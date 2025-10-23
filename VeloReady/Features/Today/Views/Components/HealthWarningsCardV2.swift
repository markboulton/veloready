import SwiftUI

/// Health Warnings card using atomic CardContainer wrapper with MVVM
/// ViewModel handles all alert filtering and state management
struct HealthWarningsCardV2: View {
    @StateObject private var viewModel = HealthWarningsCardViewModel()
    
    var body: some View {
        if viewModel.hasWarnings {
            CardContainer(
                header: CardHeader(
                    title: viewModel.title,
                    subtitle: nil,
                    badge: viewModel.severityBadge
                ),
                style: .standard
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Illness indicator (higher priority)
                    if let indicator = viewModel.illnessIndicator, indicator.isSignificant {
                        illnessWarningContent(indicator)
                            .onTapGesture {
                                viewModel.showIllnessDetail()
                            }
                    }
                    
                    // Wellness alert
                    if let alert = viewModel.wellnessAlert {
                        // Add divider if both are present
                        if viewModel.hasBothWarnings {
                            Divider()
                                .padding(.vertical, Spacing.xs)
                        }
                        
                        wellnessWarningContent(alert)
                            .onTapGesture {
                                viewModel.showWellnessDetail()
                            }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingIllnessDetail) {
                if let indicator = viewModel.illnessIndicator {
                    IllnessDetailSheet(indicator: indicator)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $viewModel.showingWellnessDetail) {
                if let alert = viewModel.wellnessAlert {
                    WellnessDetailSheet(alert: alert)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
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
                        HStack(spacing: Spacing.xs) {
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
        HStack(spacing: Spacing.xs) {
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
