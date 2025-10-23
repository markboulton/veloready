import SwiftUI

/// Health Warnings card using atomic CardContainer wrapper
/// Shows illness indicators and wellness alerts
struct HealthWarningsCardV2: View {
    @ObservedObject private var illnessService = IllnessDetectionService.shared
    @ObservedObject private var wellnessService = WellnessDetectionService.shared
    @State private var showingIllnessDetail = false
    @State private var showingWellnessDetail = false
    
    var body: some View {
        if hasWarnings {
            CardContainer(
                header: CardHeader(
                    title: hasIllnessWarning ? "Body Stress Detected" : "Health Alerts",
                    subtitle: nil,
                    badge: severityBadge
                ),
                style: .standard
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Illness indicator (higher priority)
                    if let indicator = illnessService.currentIndicator, indicator.isSignificant {
                        illnessWarningContent(indicator)
                            .onTapGesture {
                                HapticFeedback.light()
                                showingIllnessDetail = true
                            }
                    }
                    
                    // Wellness alert
                    if let alert = wellnessService.currentAlert {
                        // Add divider if both are present
                        if illnessService.currentIndicator?.isSignificant == true {
                            Divider()
                                .padding(.vertical, Spacing.xs)
                        }
                        
                        wellnessWarningContent(alert)
                            .onTapGesture {
                                HapticFeedback.light()
                                showingWellnessDetail = true
                            }
                    }
                }
            }
            .sheet(isPresented: $showingIllnessDetail) {
                if let indicator = illnessService.currentIndicator {
                    IllnessDetailSheet(indicator: indicator)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showingWellnessDetail) {
                if let alert = wellnessService.currentAlert {
                    WellnessDetailSheet(alert: alert)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    private var hasWarnings: Bool {
        (illnessService.currentIndicator?.isSignificant ?? false) || 
        (wellnessService.currentAlert != nil)
    }
    
    private var hasIllnessWarning: Bool {
        illnessService.currentIndicator?.isSignificant ?? false
    }
    
    private var warningIcon: String {
        if let indicator = illnessService.currentIndicator, indicator.isSignificant {
            return indicator.severity.icon
        } else if let alert = wellnessService.currentAlert {
            return alert.severity.icon
        }
        return Icons.Status.warningFill
    }
    
    private var severityBadge: CardHeader.Badge? {
        if let indicator = illnessService.currentIndicator, indicator.isSignificant {
            let style: VRBadge.Style = indicator.severity == .high ? .error : 
                                        indicator.severity == .moderate ? .warning : .info
            return .init(text: indicator.severity.rawValue.uppercased(), style: style)
        } else if let alert = wellnessService.currentAlert {
            return .init(text: alert.severity.rawValue.uppercased(), style: .warning)
        }
        return nil
    }
    
    @ViewBuilder
    private func illnessWarningContent(_ indicator: IllnessIndicator) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            VRText("Body Stress Detected", style: .headline, color: Color.text.primary)
            
            VRText(indicator.recommendation, style: .caption, color: Color.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Show signals
            if !indicator.signals.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(indicator.signals.prefix(3)) { signal in
                        HStack(spacing: 4) {
                            Image(systemName: signal.type.icon)
                                .font(.caption2)
                            Text(signal.type.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(Color.text.secondary)
                    }
                    
                    if indicator.signals.count > 3 {
                        Text("+\(indicator.signals.count - 3)")
                            .font(.caption2)
                            .foregroundColor(Color.text.secondary)
                    }
                }
                .padding(.top, Spacing.xs / 2)
            }
        }
    }
    
    @ViewBuilder
    private func wellnessWarningContent(_ alert: WellnessAlert) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            VRText(alert.type.title, style: .headline, color: Color.text.primary)
            
            VRText(alert.bannerMessage, style: .caption, color: Color.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Show affected metrics count
            if alert.metrics.count > 0 {
                HStack(spacing: Spacing.xs) {
                    if alert.metrics.elevatedRHR {
                        metricBadge(icon: "heart.fill", text: "RHR")
                    }
                    if alert.metrics.depressedHRV {
                        metricBadge(icon: "waveform.path.ecg", text: "HRV")
                    }
                    if alert.metrics.elevatedRespiratoryRate {
                        metricBadge(icon: "lungs.fill", text: "Resp")
                    }
                    if alert.metrics.poorSleep {
                        metricBadge(icon: "bed.double.fill", text: "Sleep")
                    }
                }
                .padding(.top, Spacing.xs / 2)
            }
        }
    }
    
    @ViewBuilder
    private func metricBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(Color.text.secondary)
    }
}

#Preview {
    HealthWarningsCardV2()
        .padding()
        .background(Color.background.primary)
}
