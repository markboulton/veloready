import SwiftUI

/// Compact wellness indicator for navigation bar - shows alert severity with RAG coloring
struct WellnessIndicator: View {
    let alert: WellnessAlert
    let onTap: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Icons.Status.warningFill)
                    .font(.caption)
                    .foregroundColor(alert.severity.color)
                
                Text(CommonContent.WellnessAlerts.keyMetricsElevated)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(alert.severity.color)
                    .lineLimit(1)
                
                Image(systemName: Icons.System.chevronRight)
                    .font(.caption2)
                    .foregroundColor(alert.severity.color)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .animation(.easeIn(duration: 0.3), value: isVisible)
        .onAppear {
            // Fade in quickly when appearing
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        // Yellow severity
        WellnessIndicator(
            alert: WellnessAlert(
                severity: .yellow,
                type: .unusualMetrics,
                detectedAt: Date(),
                metrics: WellnessAlert.AffectedMetrics(
                    elevatedRHR: true,
                    depressedHRV: false,
                    elevatedRespiratoryRate: false,
                    elevatedBodyTemp: false,
                    poorSleep: false
                ),
                trendDays: 1
            ),
            onTap: {}
        )
        
        // Amber severity
        WellnessIndicator(
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
        WellnessIndicator(
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
