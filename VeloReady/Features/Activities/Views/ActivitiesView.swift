import SwiftUI

/// Redesigned Activities view with card-based layout and progressive loading
struct ActivitiesView: View {
    @ObservedObject private var viewModel = ActivitiesViewModel.shared
    @EnvironmentObject var apiClient: IntervalsAPIClient
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @ObservedObject private var stravaAuthService = StravaAuthService.shared
    @State private var showingFilterSheet = false
    @State private var showPaywall = false
    @State private var lastStravaConnectionState: StravaConnectionState = .disconnected
    @State private var loadMoreTrigger: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Adaptive background
                Color.background.app
                    .ignoresSafeArea()
                
                Group {
                    if viewModel.isLoading && viewModel.allActivities.isEmpty {
                        ActivitiesLoadingView()
                    } else if viewModel.allActivities.isEmpty {
                        ActivitiesEmptyStateView(onRefresh: {
                            await viewModel.loadActivities(apiClient: apiClient)
                        })
                    } else {
                        activitiesScrollView
                    }
                }
                
                // Navigation gradient mask (iOS Mail style)
                NavigationGradientMask()
            }
            .navigationTitle(ActivitiesContent.title)
            .navigationBarTitleDisplayMode(.large)
            .adaptiveToolbarBackground(.hidden, for: .navigationBar)
            .adaptiveToolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if #available(iOS 26.0, *) {
                        // iOS 26+ - Native toolbar button like Apple Mail
                        Button(action: { showingFilterSheet = true }) {
                            Label(ActivitiesContent.filterButton, systemImage: Icons.System.menuDecrease)
                        }
                        .labelStyle(.iconOnly)
                    } else {
                        // iOS 25 and earlier - Custom circular button
                        CircularFilterButton(action: { showingFilterSheet = true })
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                ActivityFilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .refreshable {
                await viewModel.loadActivities(apiClient: apiClient)
            }
            .task {
                Logger.debug("📊 [Activities] View appeared - loading activities if needed")
                await viewModel.loadActivitiesIfNeeded(apiClient: apiClient)
            }
            .onChange(of: stravaAuthService.connectionState) { _, newState in
                if case .connected = newState, case .disconnected = lastStravaConnectionState {
                    Logger.debug("🔄 [Activities] Strava connected - forcing refresh")
                    Task {
                        await viewModel.forceRefresh(apiClient: apiClient)
                    }
                }
                lastStravaConnectionState = newState
            }
        }
    }
    
    // MARK: - Activities ScrollView
    
    private var activitiesScrollView: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Sparkline header
                sparklineHeader
                
                // First 3 activities (non-lazy to prevent render delay)
                ForEach(Array(viewModel.displayedActivities.prefix(3).enumerated()), id: \.element.id) { index, activity in
                    LatestActivityCardV2(activity: activity)
                        .onAppear {
                            // Progressive loading trigger
                            if index == viewModel.displayedActivities.count - 3 {
                                Logger.debug("📊 [Activities] Near end of list (index \(index)/\(viewModel.displayedActivities.count)) - loading more")
                                viewModel.loadMoreActivitiesIfNeeded()
                            }
                        }
                }
                
                // Remaining activities (lazy loaded for performance)
                if viewModel.displayedActivities.count > 3 {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(Array(viewModel.displayedActivities.dropFirst(3).enumerated()), id: \.element.id) { index, activity in
                            LatestActivityCardV2(activity: activity)
                                .onAppear {
                                    // Adjust index to account for dropFirst(3)
                                    let actualIndex = index + 3
                                    if actualIndex == viewModel.displayedActivities.count - 3 {
                                        Logger.debug("📊 [Activities] Near end of list (index \(actualIndex)/\(viewModel.displayedActivities.count)) - loading more")
                                        viewModel.loadMoreActivitiesIfNeeded()
                                    }
                                }
                        }
                    }
                }
                
                // Load more indicator
                if viewModel.hasMoreToLoad {
                    loadMoreIndicator
                }
                
                // Pro upgrade CTA for FREE users
                if !proConfig.hasProAccess && !viewModel.allActivities.isEmpty {
                    proUpgradeSection
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 120)
        }
    }
    
    // MARK: - Sparkline Header
    
    private var sparklineHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ActivitySparkline(
                dailyActivities: generateDailyActivityData(),
                alignment: .leading,
                height: 32
            )
            .onAppear {
                Logger.debug("📊 [Activities] Sparkline rendered with \(viewModel.allActivities.count) activities")
            }
        }
        .padding(.vertical, Spacing.md)
    }
    
    // MARK: - Load More Indicator
    
    private var loadMoreIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .onAppear {
                    Logger.debug("📊 [Activities] Load more indicator appeared - total displayed: \(viewModel.displayedActivities.count)/\(viewModel.allActivities.count)")
                }
            Spacer()
        }
        .padding(.vertical, Spacing.lg)
    }
    
    // MARK: - Pro Upgrade Section
    
    private var proUpgradeSection: some View {
        Button(action: { showPaywall = true }) {
            VStack(spacing: Spacing.md) {
                HStack {
                    Image(systemName: Icons.System.sparkles)
                        .foregroundColor(ColorPalette.purple)
                    VRText(ActivitiesContent.Pro.upgradeTitle, style: .headline, color: Color.text.primary)
                }
                
                VRText(ActivitiesContent.Pro.upgradeDescription, style: .caption, color: Color.text.secondary)
                    .multilineTextAlignment(.center)
                
                VRText(ActivitiesContent.Pro.upgradeButton, style: .headline, color: .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(ColorPalette.purple)
                    .cornerRadius(Spacing.cardCornerRadius)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                    .fill(Color.background.card)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    
    private func generateDailyActivityData() -> [DailyActivityData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var dailyMap: [Int: [ActivityBarData]] = [:]
        
        for activity in viewModel.allActivities {
            let activityDay = calendar.startOfDay(for: activity.startDate)
            let dayOffset = calendar.dateComponents([.day], from: activityDay, to: today).day ?? 0
            
            if dayOffset >= 0 && dayOffset <= 29 {
                let activityType: SparklineActivityType = {
                    switch activity.type {
                    case .cycling: return .cycling
                    case .running: return .running
                    case .walking: return .walking
                    case .swimming: return .swimming
                    case .strength: return .strength
                    default: return .other
                    }
                }()
                
                let duration: Double = {
                    if let dur = activity.duration, dur > 0 {
                        return dur / 60.0
                    } else if activity.intervalsActivity != nil {
                        return 60.0
                    } else {
                        return 0.0
                    }
                }()
                
                let barData = ActivityBarData(type: activityType, duration: duration)
                let key = -dayOffset
                
                if dailyMap[key] != nil {
                    dailyMap[key]?.append(barData)
                } else {
                    dailyMap[key] = [barData]
                }
            }
        }
        
        var dailyActivities: [DailyActivityData] = []
        for dayOffset in (-29)...0 {
            let activities = dailyMap[dayOffset] ?? []
            dailyActivities.append(DailyActivityData(dayOffset: dayOffset, activities: activities))
        }
        
        Logger.debug("📊 [Activities] Generated sparkline data for 30 days")
        return dailyActivities
    }
}

// MARK: - Circular Filter Button

struct CircularFilterButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.background.card)
                    .frame(width: 36, height: 36)
                
                Image(systemName: Icons.System.menuDecrease)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.text.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct ActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitiesView()
            .environmentObject(IntervalsAPIClient.shared)
    }
}
