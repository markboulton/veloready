import SwiftUI

/// Detailed stress analysis sheet
/// Matches WellnessDetailSheet design
struct StressAnalysisSheet: View {
    let alert: StressAlert
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var stressService = StressAnalysisService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with severity indicator
                    headerSection
                    
                    // Disclaimer
                    disclaimerSection
                    
                    // What we noticed
                    whatWeNoticedSection
                    
                    // 30-Day Trend Section
                    trendSection
                    
                    // Contributors Section
                    contributorsSection
                    
                    // Recommendations Section
                    recommendationsSection
                }
                .padding()
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
            Image(systemName: alert.severity.icon)
                .font(.title)
                .foregroundColor(alert.severity.color)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(severityTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(daysSinceDetection) day\(daysSinceDetection == 1 ? "" : "s") of accumulated stress")
                    .font(.subheadline)
                    .foregroundColor(ColorScale.labelSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(alert.severity.color.opacity(0.1))
        )
    }
    
    private var disclaimerSection: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: Icons.Status.info)
                .foregroundColor(ColorScale.labelSecondary)
                .font(.body)
            
            Text(StressContent.Disclaimer.text)
                .font(.caption)
                .foregroundColor(ColorScale.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ColorScale.backgroundSecondary)
        )
    }
    
    private var whatWeNoticedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What We Noticed")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(alert.recommendation)
                .font(.body)
                .foregroundColor(ColorScale.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Computed Properties
    
    private var severityTitle: String {
        switch alert.severity {
        case .elevated:
            return "Elevated Training Stress"
        case .high:
            return "High Training Stress"
        }
    }
    
    private var daysSinceDetection: Int {
        let interval = Date().timeIntervalSince(alert.detectedAt)
        let days = Int(interval / 86400)
        return max(1, days)
    }
    
    // MARK: - Trend Section
    
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("30-Day Stress Trend")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Use the same TrendChart component as recovery
            StandardCard {
                TrendChart(
                    title: "",
                    getData: { period in stressService.getStressTrendData(for: period) },
                    chartType: .bar,
                    unit: "",
                    showProBadge: false
                )
            }
        }
    }
    
    // MARK: - Contributors Section
    
    private var contributorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Contributing Factors (\(alert.contributors.count))")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: Spacing.md) {
                ForEach(alert.contributors) { contributor in
                    contributorCard(contributor)
                }
            }
        }
    }
    
    private func contributorCard(_ contributor: StressContributor) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: contributor.type.icon)
                .font(.title3)
                .foregroundColor(contributor.status.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(contributor.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorScale.labelPrimary)
                
                Text(contributor.description)
                    .font(.caption)
                    .foregroundColor(ColorScale.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ColorScale.backgroundSecondary)
        )
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            let recommendations = [
                StressContent.Recommendations.reduceVolume,
                StressContent.Recommendations.keepZ2,
                StressContent.Recommendations.prioritizeSleep,
                StressContent.Recommendations.monitorHRV
            ]
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: Icons.System.circle)
                            .font(.system(size: 6))
                            .foregroundColor(ColorScale.labelSecondary)
                            .padding(.top, 6)
                        
                        Text(recommendation)
                            .font(.body)
                            .foregroundColor(ColorScale.labelPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorScale.backgroundSecondary)
            )
            
            // Medical disclaimer
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: Icons.Status.warning)
                    .foregroundColor(ColorScale.labelSecondary)
                    .font(.caption)
                
                Text(StressContent.Recommendations.disclaimer)
                    .font(.caption)
                    .foregroundColor(ColorScale.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StressAnalysisSheet(
        alert: StressAnalysisService.shared.generateMockAlert()
    )
}

