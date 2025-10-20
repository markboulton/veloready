import SwiftUI

/// Card displaying overtraining risk assessment
struct OvertrainingRiskCard: View {
    let risk: OvertrainingRiskCalculator.RiskResult?
    
    var body: some View {
        Card(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(TrendsContent.Cards.overtrainingRisk)
                            .font(.heading)
                            .foregroundColor(.text.primary)
                        
                        if let risk = risk {
                            HStack(spacing: Spacing.xs) {
                                Text(risk.riskLevel.rawValue)
                                    .font(.title)
                                    .foregroundColor(riskColor(risk.riskLevel))
                                
                                Text("(\(Int(risk.riskScore))/100)")
                                    .font(.caption)
                                    .foregroundColor(.text.secondary)
                            }
                        } else {
                            Text(CommonContent.States.calculating)
                                .font(.body)
                                .foregroundColor(.text.secondary)
                        }
                    }
                    
                    Spacer()
                    
                }
                
                if let risk = risk {
                    riskContent(risk)
                } else {
                    emptyState
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: Icons.System.heartTextSquareOutline)
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(TrendsContent.OvertrainingRisk.noData)
                    .font(.body)
                    .foregroundColor(.text.secondary)
                
                Text(TrendsContent.OvertrainingRisk.enablePermissions)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                
                Text(TrendsContent.OvertrainingRisk.requires)
                    .font(.caption)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.OvertrainingRisk.sevenDaysRecovery)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.OvertrainingRisk.hrvData)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.OvertrainingRisk.rhrTracking)
                    }
                    HStack {
                        Text(CommonContent.Formatting.bulletPoint)
                        Text(TrendsContent.OvertrainingRisk.sleepDebt)
                    }
                }
                .font(.caption)
                .foregroundColor(.text.tertiary)
                
                Text(CommonContent.EmptyStates.checkBack)
                    .font(.caption)
                    .foregroundColor(.chart.primary)
                    .padding(.top, Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
    }
    
    private func riskContent(_ risk: OvertrainingRiskCalculator.RiskResult) -> some View {
        return VStack(alignment: .leading, spacing: Spacing.md) {
            // Risk level description
            Text(risk.riskLevel.description)
                .font(.body)
                .foregroundColor(.text.secondary)
            
            // Risk factors
            if !risk.factors.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(CommonContent.Labels.riskFactors)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    
                    ForEach(risk.factors.sorted(by: { $0.severity > $1.severity }).prefix(3), id: \.name) { factor in
                        HStack(spacing: Spacing.sm) {
                            // Severity indicator
                            Circle()
                                .fill(severityColor(factor.severity))
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(factor.name)
                                    .font(.caption)
                                    .foregroundColor(.text.primary)
                                
                                Text(factor.description)
                                    .font(.caption)
                                    .foregroundColor(.text.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, Spacing.xs)
                        .padding(.horizontal, Spacing.sm)
                        .background(Color.background.secondary)
                        .cornerRadius(Spacing.buttonCornerRadius)
                    }
                }
            }
            
            Divider()
            
            // Recommendation
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(TrendsContent.actionRequired)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                Text(risk.recommendation)
                    .font(.body)
                    .foregroundColor(.text.secondary)
            }
        }
    }
    
    private func riskColor(_ level: OvertrainingRiskCalculator.RiskLevel) -> Color {
        switch level {
        case .low:
            return ColorScale.greenAccent
        case .moderate:
            return ColorScale.amberAccent
        case .high:
            return ColorScale.redAccent
        case .critical:
            return ColorScale.redAccent
        }
    }
    
    private func severityColor(_ severity: Double) -> Color {
        if severity > 0.7 {
            return ColorScale.redAccent
        } else if severity > 0.4 {
            return ColorScale.amberAccent
        } else {
            return ColorScale.greenAccent
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // High risk
            OvertrainingRiskCard(
                risk: OvertrainingRiskCalculator.RiskResult(
                    riskScore: 68,
                    riskLevel: .high,
                    factors: [
                        OvertrainingRiskCalculator.RiskFactor(
                            name: "Recovery Score",
                            severity: 0.8,
                            description: "Poor: Recovery averaging 54%"
                        ),
                        OvertrainingRiskCalculator.RiskFactor(
                            name: "HRV Deviation",
                            severity: 0.7,
                            description: "High: HRV 18% below baseline"
                        ),
                        OvertrainingRiskCalculator.RiskFactor(
                            name: "Training Stress Balance",
                            severity: 0.6,
                            description: "High: TSB -22 (functional overreaching)"
                        )
                    ],
                    recommendation: "High overtraining risk detected (68/100). Take 3-5 recovery days with easy/no training."
                )
            )
            
            // Low risk
            OvertrainingRiskCard(
                risk: OvertrainingRiskCalculator.RiskResult(
                    riskScore: 18,
                    riskLevel: .low,
                    factors: [
                        OvertrainingRiskCalculator.RiskFactor(
                            name: "Recovery Score",
                            severity: 0.1,
                            description: "Good: Recovery averaging 78%"
                        )
                    ],
                    recommendation: "Continue current training. Your body is adapting well to the workload."
                )
            )
            
            // Empty
            OvertrainingRiskCard(risk: nil)
        }
        .padding()
    }
    .background(Color.background.primary)
}
