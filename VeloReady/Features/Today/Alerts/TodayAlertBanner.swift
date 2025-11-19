import SwiftUI

/// Banner component for displaying Today alerts (Phase 1 - V2 Architecture)
struct TodayAlertBanner: View {
    let alert: any TodayAlert
    let onDismiss: (() -> Void)?
    let onPrimaryAction: (() -> Void)?
    let onSecondaryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header row
            HStack(spacing: Spacing.sm) {
                // Icon
                if let icon = alert.icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(alert.accentColor)
                }

                // Title
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.text.primary)

                Spacer()

                // Dismiss button (if dismissible)
                if alert.isDismissible {
                    Button(action: {
                        onDismiss?()
                        TodayAlertManager.shared.dismiss(alertId: alert.id)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.text.tertiary)
                    }
                }
            }

            // Message
            Text(alert.message)
                .font(.caption)
                .foregroundColor(.text.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Actions
            if alert.primaryAction != nil || alert.secondaryAction != nil {
                HStack(spacing: Spacing.sm) {
                    // Primary action
                    if let primaryAction = alert.primaryAction {
                        Button(action: {
                            onPrimaryAction?()
                            primaryAction.action()
                        }) {
                            Text(primaryAction.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(alert.accentColor)
                                .cornerRadius(8)
                        }
                    }

                    // Secondary action
                    if let secondaryAction = alert.secondaryAction {
                        Button(action: {
                            onSecondaryAction?()
                            secondaryAction.action()
                        }) {
                            Text(secondaryAction.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.text.secondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.background.tertiary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(alert.accentColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(alert.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Container for displaying multiple alerts (stacked)
struct TodayAlertsSection: View {
    let alerts: [any TodayAlert]

    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(alerts, id: \.id) { alert in
                TodayAlertBanner(
                    alert: alert,
                    onDismiss: {
                        Logger.debug("🔕 User dismissed alert: \(alert.id)")
                    },
                    onPrimaryAction: {
                        Logger.debug("👆 User tapped primary action for alert: \(alert.id)")
                    },
                    onSecondaryAction: {
                        Logger.debug("👆 User tapped secondary action for alert: \(alert.id)")
                    }
                )
            }
        }
    }
}

// MARK: - Preview

struct TodayAlertBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Sleep Data Missing
            TodayAlertBanner(
                alert: SleepDataMissingAlert(),
                onDismiss: {},
                onPrimaryAction: {},
                onSecondaryAction: {}
            )

            // Overtraining Warning
            TodayAlertBanner(
                alert: OvertrainingAlert(),
                onDismiss: {},
                onPrimaryAction: {},
                onSecondaryAction: {}
            )

            // Low HRV
            TodayAlertBanner(
                alert: LowHRVAlert(),
                onDismiss: {},
                onPrimaryAction: {},
                onSecondaryAction: {}
            )

            // Elevated RHR
            TodayAlertBanner(
                alert: ElevatedRHRAlert(),
                onDismiss: {},
                onPrimaryAction: {},
                onSecondaryAction: {}
            )
        }
        .padding()
    }
}
