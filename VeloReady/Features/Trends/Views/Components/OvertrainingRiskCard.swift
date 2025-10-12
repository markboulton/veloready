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
                            .font(.cardTitle)
                            .foregroundColor(.text.primary)
                        
                        if let risk = risk {
                            HStack(spacing: Spacing.xs) {
                                Text(risk.riskLevel.rawValue)
                                    .font(.metricMedium)
                                    .foregroundColor(riskColor(risk.riskLevel))
                                
                                Text("(\(Int(risk.riskScore))/100)")
                                    .font(.labelPrimary)
                                    .foregroundColor(.text.secondary)
                            }
                        } else {
                            Text("Calculating...")
                                .font(.bodySecondary)
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
            Image(systemName: "heart.text.square")
                .font(.system(size: 40))
                .foregroundColor(.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                Text("Not enough health data")
                    .font(.bodySecondary)
                    .foregroundColor(.text.secondary)
                
                Text("Enable all health permissions")
                    .font(.labelSecondary)
                    .foregroundColor(.text.tertiary)
                
                Text("Risk assessment requires:")
                    .font(.labelSecondary)
                    .foregroundColor(.text.tertiary)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("•")
                        Text("7+ days of recovery scores")
                    }
                    HStack {
                        Text("•")
                        Text("HRV data from Apple Health")
                    }
                    HStack {
                        Text("•")
                        Text("Resting heart rate tracking")
                    }
                    HStack {
                        Text("•")
                        Text("Sleep data with debt calculation")
                    }
                }
                .font(.labelSecondary)
                .foregroundColor(.text.tertiary)
                
                Text("Check back after a week of tracking")
                    .font(.labelSecondary)
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
                .font(.bodySecondary)
                .foregroundColor(.text.secondary)
            
            // Risk factors
            if !risk.factors.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Risk Factors:")
                        .font(.labelPrimary)
                        .foregroundColor(.text.secondary)
                    
                    ForEach(risk.factors.sorted(by: { $0.severity > $1.severity }).prefix(3), id: \.name) { factor in
                        HStack(spacing: Spacing.sm) {
                            // Severity indicator
                            Circle()
                                .fill(severityColor(factor.severity))
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(factor.name)
                                    .font(.labelPrimary)
                                    .foregroundColor(.text.primary)
                                
                                Text(factor.description)
                                    .font(.labelSecondary)
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
                    .font(.labelPrimary)
                    .foregroundColor(.text.secondary)
                
                Text(risk.recommendation)
                    .font(.bodySecondary)
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
