import SwiftUI

/// Half-sheet detail view for wellness alerts
/// Shows detailed information about detected health patterns
struct WellnessDetailSheet: View {
    let alert: WellnessAlert
    @Environment(\.dismiss) var dismiss
    
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
                    
                    // Affected metrics
                    affectedMetricsSection
                    
                    // Recommendations
                    recommendationsSection
                }
                .padding()
            }
            .background(ColorScale.backgroundPrimary)
            .navigationTitle(WellnessContent.Detail.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: Icons.Navigation.close)
                            .foregroundColor(ColorScale.labelSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.severity.icon)
                .font(.title)
                .foregroundColor(alert.severity.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.type.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(alert.trendDays) day\(alert.trendDays == 1 ? "" : "s") of changes detected")
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: Icons.Status.info)
                .foregroundColor(ColorScale.labelSecondary)
                .font(.body)
            
            Text(WellnessContent.Detail.disclaimer)
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
        VStack(alignment: .leading, spacing: 12) {
            Text(WellnessContent.Detail.whatWeNoticed)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(WellnessContent.Detail.severityDescription(for: alert.severity.rawValue))
                .font(.body)
                .foregroundColor(ColorScale.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var affectedMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(WellnessContent.Detail.affectedMetrics)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if alert.metrics.elevatedRHR {
                    metricCard(
                        title: WellnessContent.Metrics.elevatedRHR,
                        description: WellnessContent.Metrics.elevatedRHRDescription,
                        icon: Icons.Health.heart,
                        color: ColorScale.redAccent
                    )
                }
                
                if alert.metrics.depressedHRV {
                    metricCard(
                        title: WellnessContent.Metrics.depressedHRV,
                        description: WellnessContent.Metrics.depressedHRVDescription,
                        icon: "waveform.path.ecg",
                        color: ColorScale.amberAccent
                    )
                }
                
                if alert.metrics.elevatedRespiratoryRate {
                    metricCard(
                        title: WellnessContent.Metrics.elevatedRespiratory,
                        description: WellnessContent.Metrics.elevatedRespiratoryDescription,
                        icon: Icons.Health.respiratory,
                        color: ColorScale.yellowAccent
                    )
                }
                
                if alert.metrics.elevatedBodyTemp {
                    metricCard(
                        title: WellnessContent.Metrics.elevatedTemp,
                        description: WellnessContent.Metrics.elevatedTempDescription,
                        icon: "thermometer",
                        color: ColorScale.redAccent
                    )
                }
                
                if alert.metrics.poorSleep {
                    metricCard(
                        title: WellnessContent.Metrics.poorSleep,
                        description: WellnessContent.Metrics.poorSleepDescription,
                        icon: Icons.Health.sleep,
                        color: ColorScale.amberAccent
                    )
                }
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(WellnessContent.Detail.recommendations)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Choose recommendations based on severity
            let recommendations: [String] = {
                switch alert.severity {
                case .yellow:
                    return WellnessContent.Recommendations.general
                case .amber:
                    return WellnessContent.Recommendations.moderate
                case .red:
                    return WellnessContent.Recommendations.significant
                }
            }()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
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
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: Icons.Status.warning)
                    .foregroundColor(ColorScale.labelSecondary)
                    .font(.caption)
                
                Text(WellnessContent.Recommendations.medicalDisclaimer)
                    .font(.caption)
                    .foregroundColor(ColorScale.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func metricCard(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorScale.labelPrimary)
                
                Text(description)
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
}

// MARK: - Preview

struct WellnessDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        WellnessDetailSheet(
            alert: WellnessAlert(
                severity: .amber,
                type: .sustainedElevation,
                detectedAt: Date(),
                metrics: WellnessAlert.AffectedMetrics(
                    elevatedRHR: true,
                    depressedHRV: true,
                    elevatedRespiratoryRate: true,
                    elevatedBodyTemp: false,
                    poorSleep: false
                ),
                trendDays: 2
            )
        )
    }
}
