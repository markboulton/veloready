import SwiftUI

/// Health Warnings card using atomic CardContainer wrapper with MVVM
/// ViewModel handles all alert filtering and state management
struct HealthWarningsCardV2: View {
    @StateObject private var viewModel = HealthWarningsCardViewModel()
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Illness indicator (highest priority)
            if let indicator = viewModel.illnessIndicator, indicator.isSignificant && indicator.isRecent {
                illnessWarningCard(indicator)
            }
            
            // Wellness alert
            if let alert = viewModel.wellnessAlert {
                wellnessWarningCard(alert)
            }
            
            // Sleep data missing (only if not dismissed)
            if !viewModel.hasSleepData && !viewModel.sleepDataWarningDismissed {
                sleepDataMissingCard()
            }
            
            // Network offline (lowest priority)
            if viewModel.isNetworkOffline {
                networkOfflineCard()
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
    
    @ViewBuilder
    private func illnessWarningCard(_ indicator: IllnessIndicator) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                // Icon next to heading
                Image(systemName: indicator.severity.icon)
                    .font(.title3)
                    .foregroundColor(severityColor(indicator.severity))
                
                Text(CommonContent.HealthWarnings.bodyStressDetected)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                // Severity badge
                Text(severityText(indicator.severity))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(severityColor(indicator.severity))
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(severityColor(indicator.severity).opacity(0.15))
                    .cornerRadius(4)
                
                Spacer()
                
                // Info button to trigger sheet
                Button(action: {
                    viewModel.showIllnessDetail()
                }) {
                    Image(systemName: Icons.Status.info)
                        .font(.body)
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Text(indicator.recommendation)
                .font(.subheadline)
                .foregroundColor(Color.text.secondary)
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
                .padding(.top, 4)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(severityColor(indicator.severity).opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func wellnessWarningCard(_ alert: WellnessAlert) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                // Warning icon next to heading
                Image(systemName: alert.severity.icon)
                    .font(.title3)
                    .foregroundColor(alert.severity.color)
                
                Text(alert.type.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Info button to trigger sheet
                Button(action: {
                    viewModel.showWellnessDetail()
                }) {
                    Image(systemName: Icons.Status.info)
                        .font(.body)
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Text(alert.bannerMessage)
                .font(.subheadline)
                .foregroundColor(Color.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Show affected metrics count
            if alert.metrics.count > 0 {
                HStack(spacing: Spacing.xs) {
                    if alert.metrics.elevatedRHR {
                        metricBadge(icon: Icons.Health.heartFill, text: "RHR")
                    }
                    if alert.metrics.depressedHRV {
                        metricBadge(icon: Icons.Health.heartRate, text: "HRV")
                    }
                    if alert.metrics.elevatedRespiratoryRate {
                        metricBadge(icon: Icons.Health.respiratory, text: "Resp")
                    }
                    if alert.metrics.poorSleep {
                        metricBadge(icon: Icons.Health.sleepFill, text: "Sleep")
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
    
    @ViewBuilder
    private func sleepDataMissingCard() -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                // Sleep icon next to heading (outline, purple)
                Image(systemName: Icons.Health.sleep)
                    .font(.title3)
                    .foregroundColor(ColorScale.purpleAccent)
                
                Text(CommonContent.HealthWarnings.sleepDataMissing)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(CommonContent.HealthWarnings.tipBadge)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(ColorScale.purpleAccent)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(ColorScale.purpleAccent.opacity(0.15))
                    .cornerRadius(4)
                
                Spacer()
                
                // Dismiss button
                Button(action: {
                    viewModel.dismissSleepDataWarning()
                }) {
                    Image(systemName: Icons.Navigation.close)
                        .font(.caption)
                        .foregroundColor(Color.text.secondary)
                }
            }
            
            Text(CommonContent.HealthWarnings.sleepDataMissingMessage)
                .font(.subheadline)
                .foregroundColor(Color.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorScale.purpleAccent.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func networkOfflineCard() -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                // Network icon next to heading
                Image(systemName: Icons.System.network)
                    .font(.title3)
                    .foregroundColor(Color.text.secondary)
                
                Text(CommonContent.HealthWarnings.networkOffline)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(CommonContent.HealthWarnings.debugBadge)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color.text.secondary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.text.secondary.opacity(0.15))
                    .cornerRadius(4)
            }
            
            Text(CommonContent.HealthWarnings.networkOfflineMessage)
                .font(.subheadline)
                .foregroundColor(Color.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.text.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func severityColor(_ severity: IllnessIndicator.Severity) -> Color {
        switch severity {
        case .low: return ColorScale.yellowAccent
        case .moderate: return ColorScale.amberAccent
        case .high: return ColorScale.redAccent
        }
    }
    
    private func severityText(_ severity: IllnessIndicator.Severity) -> String {
        switch severity {
        case .low: return CommonContent.HealthWarnings.severityLow.uppercased()
        case .moderate: return CommonContent.HealthWarnings.severityModerate.uppercased()
        case .high: return CommonContent.HealthWarnings.severityHigh.uppercased()
        }
    }
}

#Preview {
    HealthWarningsCardV2()
        .padding()
        .background(Color.background.primary)
}
