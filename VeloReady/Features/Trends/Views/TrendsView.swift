import SwiftUI

/// Main Trends view - PRO feature
/// Shows performance and health trends over time
struct TrendsView: View {
    @ObservedObject private var viewState = TrendsViewState.shared
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Adaptive background (light grey in light mode, black in dark mode)
                Color.background.app
                    .ignoresSafeArea()

                Group {
                    if proConfig.hasProAccess {
                        trendsContent
                    } else {
                        proGate
                    }
                }

                // Navigation gradient mask (iOS Mail style)
                NavigationGradientMask()
            }
            .navigationTitle(TrendsContent.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .task {
                // Fix critical bug: Load data when view appears
                await viewState.load()
            }
        }
    }
    
    // MARK: - Trends Content

    private var trendsContent: some View {
        WeeklyReportView()
    }
    
    // MARK: - Pro Gate
    
    private var proGate: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.gradient.proIcon.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: Icons.DataSource.intervalsICU)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Color.gradient.proIcon)
            }
            
            // Title
            Text(TrendsContent.unlockTrends)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.text.primary)
                .multilineTextAlignment(.center)
            
            // Description
            VStack(alignment: .leading, spacing: Spacing.md) {
                FeatureBullet(
                    text: "Track FTP evolution over time"
                )
                
                FeatureBullet(
                    text: "Monitor recovery and HRV trends"
                )
                
                FeatureBullet(
                    text: "Analyze weekly training load patterns"
                )
                
                FeatureBullet(
                    text: "Discover how recovery affects your power output"
                )
                
                FeatureBullet(
                    text: "See correlations no other app can show"
                )
            }
            .padding(.horizontal, Spacing.xl)
            
            Spacer()
            
            // Upgrade Button
            Button(action: { showPaywall = true }) {
                HStack {
                    Image(systemName: Icons.System.star)
                    Text(TrendsContent.upgradeToPro)
                }
                .font(.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(Color.gradient.pro)
                .cornerRadius(Spacing.buttonCornerRadius)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .padding(Spacing.lg)
        .background(Color.background.primary)
    }
}

// MARK: - Supporting Views

private struct FeatureBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text(TrendsContent.bulletPoint)
                .font(.body)
                .foregroundColor(.text.primary)
                .frame(width: 12)

            Text(text)
                .font(.body)
                .foregroundColor(.text.primary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Trends - PRO") {
    TrendsView()
        .onAppear {
            ProFeatureConfig.shared.isProUser = true
        }
}

#Preview("Trends - Free") {
    TrendsView()
        .onAppear {
            ProFeatureConfig.shared.isProUser = false
            ProFeatureConfig.shared.isInTrialPeriod = false
        }
}
