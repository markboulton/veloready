import SwiftUI

/// Combined health warnings card showing illness and wellness alerts
struct HealthWarningsCard: View {
    @ObservedObject private var illnessService = IllnessDetectionService.shared
    @ObservedObject private var wellnessService = WellnessDetectionService.shared
    @State private var showingIllnessDetail = false
    @State private var showingWellnessDetail = false
    
    var body: some View {
        // Only show if there's an illness indicator or wellness alert
        if hasWarnings {
            StandardCard {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom header with red styling for illness
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: warningIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(hasIllnessWarning ? ColorScale.redAccent : Color.text.secondary)
                        
                        Text(hasIllnessWarning ? "Body Stress Detected" : "Health Alerts")
                            .font(.heading)
                            .foregroundColor(hasIllnessWarning ? ColorScale.redAccent : Color.text.primary)
                        
                        Spacer()
                    }
                    .padding(.bottom, Spacing.md)
                    
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
    
    @ViewBuilder
    private func illnessWarningContent(_ indicator: IllnessIndicator) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Body Stress Detected")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(indicator.severity.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(severityColor(indicator.severity))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor(indicator.severity).opacity(0.15))
                    .cornerRadius(4)
            }
            
            Text(indicator.recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Show signals
            if !indicator.signals.isEmpty {
                HStack(spacing: 6) {
                    ForEach(indicator.signals.prefix(3)) { signal in
                        HStack(spacing: 4) {
                            Image(systemName: signal.type.icon)
                                .font(.caption2)
                            Text(signal.type.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if indicator.signals.count > 3 {
                        Text("+\(indicator.signals.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    @ViewBuilder
    private func wellnessWarningContent(_ alert: WellnessAlert) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(alert.type.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(alert.severity.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(alert.severity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(alert.severity.color.opacity(0.15))
                    .cornerRadius(4)
            }
            
            Text(alert.bannerMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Show affected metrics count
            if alert.metrics.count > 0 {
                HStack(spacing: 6) {
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
                        metricBadge(icon: "moon.fill", text: "Sleep")
                    }
                }
                .padding(.top, 4)
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
        .foregroundColor(.secondary)
    }
    
    private func severityColor(_ severity: IllnessIndicator.Severity) -> Color {
        switch severity {
        case .low: return ColorScale.yellowAccent
        case .moderate: return ColorScale.amberAccent
        case .high: return ColorScale.redAccent
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HealthWarningsCard()
    }
    .padding()
    .background(Color.background.primary)
}
