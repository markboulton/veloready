import SwiftUI

/// Warning banner for wellness alerts - appears under the daily summary rings
struct WellnessBanner: View {
    let alert: WellnessAlert
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Warning icon with severity-based color
                Image(systemName: alert.severity.icon)
                    .font(.caption)
                    .foregroundColor(alert.severity.color)
                
                // Banner message
                Text(alert.bannerMessage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ColorScale.labelPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Chevron to indicate it's tappable
                Image(systemName: Icons.System.chevronRight)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                Rectangle()
                    .fill(alert.severity.color.opacity(0.1))
                    .overlay(
                        Rectangle()
                            .stroke(alert.severity.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct WellnessBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Yellow severity
            WellnessBanner(
                alert: WellnessAlert(
                    severity: .yellow,
                    type: .unusualMetrics,
                    detectedAt: Date(),
                    metrics: WellnessAlert.AffectedMetrics(
                        elevatedRHR: true,
                        depressedHRV: true,
                        elevatedRespiratoryRate: false,
                        elevatedBodyTemp: false,
                        poorSleep: false
                    ),
                    trendDays: 2
                ),
                onTap: {}
            )
            
            // Amber severity
            WellnessBanner(
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
                ),
                onTap: {}
            )
            
            // Red severity
            WellnessBanner(
                alert: WellnessAlert(
                    severity: .red,
                    type: .multipleIndicators,
                    detectedAt: Date(),
                    metrics: WellnessAlert.AffectedMetrics(
                        elevatedRHR: true,
                        depressedHRV: true,
                        elevatedRespiratoryRate: true,
                        elevatedBodyTemp: true,
                        poorSleep: false
                    ),
                    trendDays: 3
                ),
                onTap: {}
            )
        }
        .padding()
    }
}
