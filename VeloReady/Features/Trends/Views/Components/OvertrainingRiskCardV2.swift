import SwiftUI

/// Overtraining Risk card using atomic CardContainer wrapper
/// Assesses overtraining risk based on recovery, HRV, sleep, and training load
/// Shows risk score (0-100), risk level, contributing factors, and recommendations
struct OvertrainingRiskCardV2: View {
    let risk: OvertrainingRiskCalculator.RiskResult?
    
    private var badge: CardHeader.Badge? {
        guard let risk = risk else { return nil }
        
        switch risk.riskLevel {
        case .low:
            return .init(text: "LOW", style: .success)
        case .moderate:
            return .init(text: "MODERATE", style: .info)
        case .high:
            return .init(text: "HIGH", style: .warning)
        case .critical:
            return .init(text: "CRITICAL", style: .error)
        }
    }
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: TrendsContent.Cards.overtrainingRisk,
                subtitle: risk.map { "\($0.riskLevel.rawValue) (\(Int($0.riskScore))/100)" } ?? CommonContent.States.calculating,
                badge: badge
            ),
            style: .standard
        ) {
            if let risk = risk {
                riskContentView(risk)
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: Icons.System.heartTextSquareOutline)
                .font(.system(size: 40))
                .foregroundColor(Color.text.tertiary)
            
            VStack(spacing: Spacing.xs) {
                VRText(
                    TrendsContent.OvertrainingRisk.noData,
                    style: .body,
                    color: Color.text.secondary
                )
                .multilineTextAlignment(.center)
                
                VRText(
                    TrendsContent.OvertrainingRisk.enablePermissions,
                    style: .caption,
                    color: Color.text.tertiary
                )
                
                VRText(
                    TrendsContent.OvertrainingRisk.requires,
                    style: .caption,
                    color: Color.text.tertiary
                )
                .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.OvertrainingRisk.sevenDaysRecovery, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.OvertrainingRisk.hrvData, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.OvertrainingRisk.rhrTracking, style: .caption, color: Color.text.tertiary)
                    }
                    HStack {
                        VRText(CommonContent.Formatting.bulletPoint, style: .caption, color: Color.text.tertiary)
                        VRText(TrendsContent.OvertrainingRisk.sleepDebt, style: .caption, color: Color.text.tertiary)
                    }
                }
                
                VRText(
                    CommonContent.EmptyStates.checkBack,
                    style: .caption,
                    color: Color.chart.primary
                )
                .padding(.top, Spacing.sm)
            }
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Risk Content
    
    private func riskContentView(_ risk: OvertrainingRiskCalculator.RiskResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Risk level description
            VRText(
                risk.riskLevel.description,
                style: .body,
                color: Color.text.secondary
            )
            
            // Risk factors (show top 3 by severity)
            if !risk.factors.isEmpty {
                riskFactorsSection(risk.factors)
            }
            
            Divider()
            
            // Recommendation
            VStack(alignment: .leading, spacing: Spacing.xs) {
                VRText(
                    TrendsContent.actionRequired,
                    style: .caption,
                    color: Color.text.secondary
                )
                
                VRText(
                    risk.recommendation,
                    style: .body,
                    color: Color.text.secondary
                )
            }
        }
    }
    
    // MARK: - Risk Factors Section
    
    private func riskFactorsSection(_ factors: [OvertrainingRiskCalculator.RiskFactor]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            VRText(
                CommonContent.Labels.riskFactors,
                style: .caption,
                color: Color.text.secondary
            )
            
            ForEach(factors.sorted(by: { $0.severity > $1.severity }).prefix(3), id: \.name) { factor in
                riskFactorRow(factor)
            }
        }
    }
    
    // MARK: - Risk Factor Row
    
    private func riskFactorRow(_ factor: OvertrainingRiskCalculator.RiskFactor) -> some View {
        HStack(spacing: Spacing.sm) {
            // Severity indicator
            Circle()
                .fill(severityColor(factor.severity))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                VRText(
                    factor.name,
                    style: .caption,
                    color: Color.text.primary
                )
                
                VRText(
                    factor.description,
                    style: .caption,
                    color: Color.text.secondary
                )
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(Color.background.secondary)
        .cornerRadius(Spacing.buttonCornerRadius)
    }
    
    // MARK: - Helper Methods
    
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

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // High risk
            OvertrainingRiskCardV2(
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
                        ),
                        OvertrainingRiskCalculator.RiskFactor(
                            name: "Sleep Debt",
                            severity: 0.5,
                            description: "Moderate: 3.2 hours accumulated debt"
                        )
                    ],
                    recommendation: "High overtraining risk detected (68/100). Take 3-5 recovery days with easy/no training."
                )
            )
            
            // Moderate risk
            OvertrainingRiskCardV2(
                risk: OvertrainingRiskCalculator.RiskResult(
                    riskScore: 42,
                    riskLevel: .moderate,
                    factors: [
                        OvertrainingRiskCalculator.RiskFactor(
                            name: "Training Load",
                            severity: 0.5,
                            description: "Elevated: TSS significantly above baseline"
                        ),
                        OvertrainingRiskCalculator.RiskFactor(
                            name: "Sleep Quality",
                            severity: 0.3,
                            description: "Below optimal: Sleep score averaging 72%"
                        )
                    ],
                    recommendation: "Moderate risk. Monitor recovery closely and consider an extra rest day this week."
                )
            )
            
            // Low risk
            OvertrainingRiskCardV2(
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
            OvertrainingRiskCardV2(risk: nil)
        }
        .padding()
    }
    .background(Color.background.primary)
}
