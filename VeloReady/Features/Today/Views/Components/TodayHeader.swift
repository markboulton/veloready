import SwiftUI

/// Custom header for Today view with inline wellness indicator
struct TodayHeader: View {
    let alert: WellnessAlert?
    let onAlertTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            
            if let alert = alert {
                WellnessIndicator(alert: alert, onTap: onAlertTap)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
    }
}

#Preview {
    VStack {
        TodayHeader(
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
            onAlertTap: {}
        )
        
        Spacer()
    }
}
