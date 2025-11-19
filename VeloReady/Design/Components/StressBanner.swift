import SwiftUI

/// Banner for stress alerts - standardized to match canonical wellness alert design
/// Uses consistent RAG coloring, outlined icons, and design system tokens
struct StressBanner: View {
    let alert: StressAlert
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    // Outlined alert icon (top-left) - canonical pattern
                    Image(systemName: alert.severity.icon)
                        .font(.title3)
                        .foregroundColor(alert.severity.color)

                    Text(StressContent.Banner.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    // Severity badge
                    Text(alert.severity.rawValue.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(alert.severity.color)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(alert.severity.color.opacity(0.15))
                        .cornerRadius(4)

                    Spacer()

                    // Info icon (top-right) - canonical pattern
                    Image(systemName: Icons.Status.info)
                        .font(.body)
                        .foregroundColor(Color.text.secondary)
                }

                // Description sentence
                Text(alert.bannerMessage)
                    .font(.subheadline)
                    .foregroundColor(Color.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Contributor badges (matching metric badges pattern)
                if !alert.contributors.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        ForEach(alert.contributors.prefix(3)) { contributor in
                            HStack(spacing: 4) {
                                Image(systemName: contributor.type.icon)
                                    .font(.caption2)
                                Text(contributor.type.label)
                                    .font(.caption2)
                            }
                            .foregroundColor(Color.text.secondary)
                        }

                        if alert.contributors.count > 3 {
                            Text("+\(alert.contributors.count - 3)")
                                .font(.caption2)
                                .foregroundColor(Color.text.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alert.severity.color.opacity(0.1))
            .cornerRadius(12)
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

