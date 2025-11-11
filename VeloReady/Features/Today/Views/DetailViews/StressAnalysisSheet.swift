import SwiftUI
import Charts

/// Detailed stress analysis sheet
/// Shows comprehensive breakdown of stress factors and recommendations
struct StressAnalysisSheet: View {
    let alert: StressAlert
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.background.app
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Current State Section
                        currentStateSection
                        
                        // 30-Day Trend Section
                        trendSection
                        
                        // Contributors Section
                        contributorsSection
                        
                        // What This Means Section
                        explanationSection
                        
                        // Recommendations Section
                        recommendationsSection
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 120)
                }
                
                // Navigation gradient mask
                NavigationGradientMask()
            }
            .navigationTitle(StressContent.title)
            .navigationBarTitleDisplayMode(.inline)
            .adaptiveToolbarBackground(.hidden, for: .navigationBar)
            .adaptiveToolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text(StressContent.Actions.gotIt)
                            .font(.headline)
                            .foregroundColor(ColorScale.blueAccent)
                    }
                }
            }
        }
    }
    
    // MARK: - Current State Section
    
    private var currentStateSection: some View {
        StandardCard(title: StressContent.Sections.currentState) {
            VStack(spacing: Spacing.md) {
                // Acute Stress
                stressMetricRow(
                    label: StressContent.Metrics.acuteStress,
                    value: alert.acuteStress,
                    severity: alert.severity
                )
                
                Divider()
                
                // Chronic Stress
                stressMetricRow(
                    label: StressContent.Metrics.chronicStress,
                    value: alert.chronicStress,
                    severity: alert.severity
                )
                
                Divider()
                
                // Trend
                HStack {
                    Text(StressContent.Metrics.trend)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.text.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: alert.trend.icon)
                            .font(.caption)
                        Text(alert.trend.description)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(alert.severity.color)
                }
            }
        }
    }
    
    private func stressMetricRow(label: String, value: Int, severity: StressAlert.Severity) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.text.secondary)
            
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(severity.color)
                
                // Status badge
                Text(statusLabel(for: value))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs / 2)
                    .background(
                        Capsule()
                            .fill(severity.color)
                    )
            }
        }
    }
    
    private func statusLabel(for value: Int) -> String {
        switch value {
        case 0...35:
            return StressContent.Status.low
        case 36...60:
            return StressContent.Status.moderate
        case 61...80:
            return StressContent.Status.elevated
        default:
            return StressContent.Status.high
        }
    }
    
    // MARK: - Trend Section
    
    private var trendSection: some View {
        StandardCard(title: StressContent.Sections.trend) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Mock trend chart
                trendChart
                
                // Legend
                HStack(spacing: Spacing.lg) {
                    Spacer()
                    
                    legendItem(color: ColorScale.greenAccent, label: StressContent.Chart.lowLabel)
                    legendItem(color: ColorScale.amberAccent, label: StressContent.Chart.moderateLabel)
                    legendItem(color: ColorScale.redAccent, label: StressContent.Chart.highLabel)
                }
                .font(.caption)
                
                // "You are here" indicator
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text(StressContent.Metrics.youAreHere)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
            }
        }
    }
    
    private var trendChart: some View {
        // Simple bar chart visualization
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<30, id: \.self) { index in
                let height = mockTrendHeight(for: index)
                let color = mockTrendColor(for: height)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 8, height: height)
            }
        }
        .frame(height: 120)
    }
    
    private func mockTrendHeight(for index: Int) -> CGFloat {
        // Generate increasing trend
        let base: CGFloat = 40
        let increment: CGFloat = 2.5
        let noise: CGFloat = CGFloat.random(in: -10...10)
        return min(120, max(20, base + (CGFloat(index) * increment) + noise))
    }
    
    private func mockTrendColor(for height: CGFloat) -> Color {
        switch height {
        case 0...40:
            return ColorScale.greenAccent
        case 41...80:
            return ColorScale.amberAccent
        default:
            return ColorScale.redAccent
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: Spacing.xs / 2) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.text.secondary)
        }
    }
    
    // MARK: - Contributors Section
    
    private var contributorsSection: some View {
        StandardCard(title: StressContent.Sections.contributors) {
            VStack(spacing: Spacing.md) {
                ForEach(alert.contributors) { contributor in
                    contributorRow(contributor)
                    
                    if contributor.id != alert.contributors.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
    
    private func contributorRow(_ contributor: StressContributor) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                // Icon and name
                HStack(spacing: Spacing.sm) {
                    Image(systemName: contributor.type.icon)
                        .font(.caption)
                        .foregroundColor(contributor.status.color)
                        .frame(width: 20)
                    
                    Text(contributor.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Status and points
                HStack(spacing: Spacing.sm) {
                    Text(contributor.status.label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(contributor.status.color)
                    
                    Text("(\(contributor.points) pts)")
                        .font(.caption)
                        .foregroundColor(.text.tertiary)
                }
            }
            
            // Description
            Text(contributor.description)
                .font(.caption)
                .foregroundColor(.text.secondary)
                .padding(.leading, 32)
        }
    }
    
    // MARK: - Explanation Section
    
    private var explanationSection: some View {
        StandardCard(title: StressContent.Sections.whatThisMeans) {
            Text(alert.recommendation)
                .font(.subheadline)
                .foregroundColor(.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        StandardCard(title: StressContent.Sections.recommendation) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Main recommendation
                Text(StressContent.Recommendations.implementRecoveryWeek)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorScale.greenAccent)
                
                // Action items
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    recommendationItem(StressContent.Recommendations.reduceVolume)
                    recommendationItem(StressContent.Recommendations.keepZ2)
                    recommendationItem(StressContent.Recommendations.prioritizeSleep)
                    recommendationItem(StressContent.Recommendations.monitorHRV)
                }
                
                Divider()
                
                // Expected recovery time
                Text(StressContent.Recommendations.expectedRecovery(days: 7))
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func recommendationItem(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.text.secondary)
    }
}

// MARK: - Preview

#Preview {
    StressAnalysisSheet(
        alert: StressAnalysisService.shared.generateMockAlert()
    )
}

