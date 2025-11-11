import SwiftUI

/// Banner for stress alerts - appears under the daily summary rings
/// Follows the same pattern as WellnessBanner and IllnessAlertBanner
struct StressBanner: View {
    let alert: StressAlert
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.xs / 2) {
            HStack(spacing: Spacing.xs) {
                // Icon in circle (matching illness banner)
                ZStack {
                    Circle()
                        .fill(severityColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: alert.severity.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(severityColor)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(alert.bannerMessage)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Severity badge (matching illness banner)
                        Text(alert.severity.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(severityColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(severityColor.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    Text(alert.severity == .elevated ? StressContent.Banner.elevated : StressContent.Banner.high)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Info icon button (matching illness banner tap target)
                    Button(action: onTap) {
                        HStack(spacing: 4) {
                            Image(systemName: Icons.Status.info)
                                .font(.caption2)
                            Text("Learn more")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    }
                }
            }
            .padding()
            .background(severityColor.opacity(0.05))
            .overlay(
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(severityColor),
                alignment: .leading
            )
        }
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .elevated:
            return ColorScale.amberAccent
        case .high:
            return ColorScale.redAccent
        }
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

