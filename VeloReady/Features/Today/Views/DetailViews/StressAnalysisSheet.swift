import SwiftUI
import Charts

/// Detailed stress analysis sheet
/// Shows comprehensive breakdown of stress factors and recommendations
struct StressAnalysisSheet: View {
    let alert: StressAlert
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    // Header with severity
                    headerSection
                    
                    // 30-Day Trend Section
                    trendSection
                    
                    // Contributors Section
                    contributorsSection
                    
                    // What This Means Section
                    explanationSection
                    
                    // Recommendations Section
                    recommendationsSection
                }
                .padding(Spacing.lg)
            }
            .background(ColorScale.backgroundPrimary)
            .navigationTitle(StressContent.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.light()
                        dismiss()
                    }) {
                        Image(systemName: Icons.Navigation.close)
                            .foregroundColor(ColorScale.labelSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: Spacing.md) {
            // Severity icon
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: alert.severity.icon)
                    .font(.title2)
                    .foregroundColor(severityColor)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(severityTitle)
                    .font(.title3.weight(.bold))
                    .foregroundColor(ColorScale.labelPrimary)
                
                Text("Acute: \(alert.acuteStress) • Chronic: \(alert.chronicStress)")
                    .font(.body)
                    .foregroundColor(ColorScale.labelSecondary)
                
                Text("Detected \(timeAgoText)")
                    .font(.caption)
                    .foregroundColor(ColorScale.labelTertiary)
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                .fill(severityColor.opacity(0.08))
        )
    }
    
    // MARK: - Computed Properties
    
    private var severityColor: Color {
        switch alert.severity {
        case .normal:
            return ColorScale.greenAccent
        case .elevated:
            return ColorScale.amberAccent
        case .high:
            return ColorScale.redAccent
        }
    }
    
    private var severityTitle: String {
        switch alert.severity {
        case .normal:
            return "Normal Training Stress"
        case .elevated:
            return "Elevated Training Stress"
        case .high:
            return "High Training Stress"
        }
    }
    
    private var timeAgoText: String {
        let interval = Date().timeIntervalSince(alert.detectedAt)
        let hours = Int(interval / 3600)
        
        if hours < 1 {
            return "just now"
        } else if hours == 1 {
            return "1 hour ago"
        } else if hours < 24 {
            return "\(hours) hours ago"
        } else {
            let days = hours / 24
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
    }
    
    // MARK: - Trend Section
    
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("30-Day Trend")
                .font(.title3.weight(.bold))
                .foregroundColor(ColorScale.labelPrimary)
            
            // Bar chart (matching recovery/sleep design)
            trendChart
            
            Text("Tracking your training stress helps identify when you need recovery. The trend shows increasing stress leading to current state.")
                .font(.body)
                .foregroundColor(ColorScale.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var trendChart: some View {
        VStack(spacing: Spacing.sm) {
            // Chart
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    let height = mockTrendHeight(for: index)
                    let value = mockTrendValue(for: index)
                    let color = mockTrendColor(for: value)
                    
                    VStack(spacing: 0) {
                        // Colored top indicator (2-3px)
                        Rectangle()
                            .fill(color)
                            .frame(width: 8, height: 3)
                        
                        // Main bar (dark grey matching recovery charts)
                        Rectangle()
                            .fill(ColorPalette.neutral300)
                            .frame(width: 8, height: max(0, height - 3))
                    }
                }
            }
            .frame(height: 100)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                    .fill(ColorScale.backgroundSecondary)
            )
        }
    }
    
    private func mockTrendValue(for index: Int) -> Int {
        // Generate increasing trend (values 0-100)
        let base: Double = 30
        let increment: Double = 2.0
        let noise: Double = Double.random(in: -5...5)
        return min(100, max(0, Int(base + (Double(index) * increment) + noise)))
    }
    
    private func mockTrendHeight(for index: Int) -> CGFloat {
        // Convert value to height
        let value = mockTrendValue(for: index)
        return CGFloat(value) * 0.9 + 10 // Scale to fit chart height
    }
    
    private func mockTrendColor(for value: Int) -> Color {
        switch value {
        case 0...40:
            return ColorScale.greenAccent
        case 41...70:
            return ColorScale.amberAccent
        default:
            return ColorScale.redAccent
        }
    }
    
    // MARK: - Contributors Section
    
    private var contributorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Key Contributors (\(alert.contributors.count))")
                .font(.title3.weight(.bold))
                .foregroundColor(ColorScale.labelPrimary)
            
            VStack(spacing: Spacing.sm) {
                ForEach(alert.contributors) { contributor in
                    contributorCard(contributor)
                }
            }
        }
    }
    
    private func contributorCard(_ contributor: StressContributor) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: contributor.type.icon)
                    .font(.title3)
                    .foregroundColor(contributor.status.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(contributor.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(ColorScale.labelPrimary)
                    
                    Text("\(contributor.status.label) • +\(contributor.points) pts")
                        .font(.caption)
                        .foregroundColor(contributor.status.color)
                }
                
                Spacer()
            }
            
            Text(contributor.description)
                .font(.caption)
                .foregroundColor(ColorScale.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                .fill(ColorScale.backgroundSecondary)
        )
    }
    
    // MARK: - Explanation Section
    
    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What This Means")
                .font(.title3.weight(.bold))
                .foregroundColor(ColorScale.labelPrimary)
            
            Text(alert.recommendation)
                .font(.body)
                .foregroundColor(ColorScale.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recommendations")
                .font(.title3.weight(.bold))
                .foregroundColor(ColorScale.labelPrimary)
            
            let recommendations = [
                StressContent.Recommendations.reduceVolume,
                StressContent.Recommendations.keepZ2,
                StressContent.Recommendations.prioritizeSleep,
                StressContent.Recommendations.monitorHRV
            ]
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: Icons.Status.checkmark)
                            .font(.caption)
                            .foregroundColor(severityColor)
                            .padding(.top, 2)
                        
                        Text(recommendation)
                            .font(.body)
                            .foregroundColor(ColorScale.labelPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                    .fill(ColorScale.backgroundSecondary)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    StressAnalysisSheet(
        alert: StressAnalysisService.shared.generateMockAlert()
    )
}

