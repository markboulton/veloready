import SwiftUI

/// Banner for stress alerts - appears under the daily summary rings
/// Matches IllnessAlertBanner design exactly
struct StressBanner: View {
    let alert: StressAlert
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xs / 2) {
                HStack(spacing: Spacing.xs) {
                    // Icon in circle (top-left aligned)
                    ZStack {
                        Circle()
                            .fill(alert.severity.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: alert.severity.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(alert.severity.color)
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Row 1: Heading + Badge
                        HStack {
                            Text(StressContent.Banner.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Severity badge
                            Text(alert.severity.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(alert.severity.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(alert.severity.color.opacity(0.15))
                                .cornerRadius(4)
                        }
                        
                        // Row 2: Description in grey
                        Text(alert.bannerMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Row 3: Contributor icons (show top 3)
                        if !alert.contributors.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(alert.contributors.prefix(3)) { contributor in
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: contributor.type.icon)
                                            .font(.caption2)
                                        Text(contributor.type.label)
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                if alert.contributors.count > 3 {
                                    Text("+\(alert.contributors.count - 3)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    // Info icon (right-aligned)
                    Image(systemName: Icons.Status.info)
                        .font(.body)
                        .foregroundColor(Color.text.secondary)
                }
                .padding()
                .background(alert.severity.color.opacity(0.05))
                .overlay(
                    Rectangle()
                        .frame(width: 4)
                        .foregroundColor(alert.severity.color),
                    alignment: .leading
                )
            }
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

