import SwiftUI

/// Redesigned Activities view with card-based layout and progressive loading
struct ActivitiesView: View {
    @ObservedObject private var viewModel = ActivitiesViewModel.shared
    @EnvironmentObject var apiClient: IntervalsAPIClient
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @ObservedObject private var stravaAuthService = StravaAuthService.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
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
            .if(networkMonitor.isConnected) { view in
                view.refreshable {
                    await viewModel.loadActivities(apiClient: apiClient)
                }
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
                // Paginated activities list with LazyVGrid
                LazyVGrid(columns: [GridItem(.flexible())], spacing: Spacing.md) {
                    ForEach(Array(viewModel.paginatedActivities.enumerated()), id: \.element.id) { index, activity in
                        LatestActivityCardV2(activity: activity)
                            .onAppear {
                                // Trigger pagination when reaching near end (last 3 items)
                                if index == viewModel.paginatedActivities.count - 3 && viewModel.hasMorePages {
                                    Logger.debug("📊 [Activities] Near end of page (\(index + 1)/\(viewModel.paginatedActivities.count)) - loading next page")
                                    viewModel.loadNextPage()
                                }
                            }
                    }
                    
                    // Pagination loading indicator
                    if viewModel.isLoadingPage {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding(.vertical, Spacing.lg)
                            Spacer()
                        }
                    }
                }
                
                // Load more indicator (for old progressive loading)
                if viewModel.hasMoreToLoad && !viewModel.hasMorePages {
                    loadMoreIndicator
                }
                
                // Pro upgrade CTA for FREE users
                if !proConfig.hasProAccess && !viewModel.allActivities.isEmpty {
                    proUpgradeSection
                }
            }
            .padding(.top, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 120)
        }
    }
    
    // MARK: - Load More Indicator
    
    private var loadMoreIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .onAppear {
                    Logger.debug("📊 [Activities] Load more indicator appeared - total displayed: \(viewModel.paginatedActivities.count)/\(viewModel.allActivities.count)")
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
