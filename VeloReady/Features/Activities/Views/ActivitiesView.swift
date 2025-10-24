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
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CircularFilterButton(action: { showingFilterSheet = true })
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
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Sparkline header (outside of sections)
                sparklineHeader
                    .padding(.horizontal, Spacing.xl)
                
                // Activities grouped by month with sticky headers
                ForEach(viewModel.displayedGroupedActivities, id: \.key) { monthGroup in
                    Section {
                        ForEach(Array(monthGroup.value.enumerated()), id: \.element.id) { index, activity in
                            LatestActivityCardV2(activity: activity)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.xs)
                                .onAppear {
                                    // Progressive loading: when user scrolls near the end, load more
                                    let totalDisplayed = viewModel.displayedActivities.count
                                    let activityIndex = viewModel.displayedActivities.firstIndex(where: { $0.id == activity.id }) ?? 0
                                    
                                    if activityIndex == totalDisplayed - 3 {
                                        Logger.debug("📊 [Activities] Near end of list (index \(activityIndex)/\(totalDisplayed)) - loading more")
                                        viewModel.loadMoreActivitiesIfNeeded()
                                    }
                                }
                        }
                    } header: {
                        SectionHeader(monthGroup.key, style: .monthYear)
                    }
                }
                
                // Load more indicator
                if viewModel.hasMoreToLoad {
                    loadMoreIndicator
                        .padding(.horizontal, Spacing.xl)
                }
                
                // Pro upgrade CTA for FREE users
                if !proConfig.hasProAccess && !viewModel.allActivities.isEmpty {
                    proUpgradeSection
                        .padding(.horizontal, Spacing.xl)
                }
            }
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
