import SwiftUI

/// Banner for stress alerts - appears under the daily summary rings
/// Follows the same pattern as WellnessBanner and IllnessAlertBanner
struct StressBanner: View {
    let alert: StressAlert
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                // Warning icon with severity-based color
                Image(systemName: alert.severity.icon)
                    .font(.caption)
                    .foregroundColor(alert.severity.color)
                
                // Banner message
                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text(alert.bannerMessage)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(ColorScale.labelPrimary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Details link with arrow
                HStack(spacing: Spacing.xs / 2) {
                    Text(StressContent.detailsLink)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(ColorScale.blueAccent)
                    
                    Image(systemName: Icons.System.chevronRight)
                        .font(.caption)
                        .foregroundColor(ColorScale.blueAccent)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(alert.severity.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(alert.severity.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Elevated Stress") {
    VStack(spacing: Spacing.md) {
        StressBanner(
            alert: StressAlert(
                severity: .elevated,
                acuteStress: 72,
                chronicStress: 78,
                trend: .increasing,
                contributors: [],
                recommendation: "Test recommendation",
                detectedAt: Date()
            ),
            onTap: {}
        )
        .padding()
        
        StressBanner(
            alert: StressAlert(
                severity: .high,
                acuteStress: 85,
                chronicStress: 88,
                trend: .increasing,
                contributors: [],
                recommendation: "Test recommendation",
                detectedAt: Date()
            ),
            onTap: {}
        )
        .padding()
    }
    .background(Color.background.app)
}

