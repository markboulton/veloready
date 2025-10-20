import Foundation

/// Calculates overtraining risk from multiple physiological signals
struct OvertrainingRiskCalculator {
    
    // MARK: - Risk Level
    
    enum RiskLevel: String {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case critical = "Critical"
        
        var description: String {
            switch self {
            case .low:
                return TrendsContent.OvertrainingRisk.lowDescription
            case .moderate:
                return TrendsContent.OvertrainingRisk.moderateDescription
            case .high:
                return TrendsContent.OvertrainingRisk.highDescription
            case .critical:
                return TrendsContent.OvertrainingRisk.criticalDescription
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "checkmark.shield.fill"
            case .moderate: return "exclamationmark.triangle.fill"
            case .high: return "exclamationmark.octagon.fill"
            case .critical: return "xmark.octagon.fill"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "recovery.green"
            case .moderate: return "recovery.amber"
            case .high: return "recovery.red"
            case .critical: return "recovery.red"
            }
        }
    }
    
    struct RiskResult {
        let riskScore: Double  // 0-100
        let riskLevel: RiskLevel
        let factors: [RiskFactor]
        let recommendation: String
    }
    
    struct RiskFactor {
        let name: String
        let severity: Double  // 0-1
        let description: String
    }
    
    // MARK: - Risk Calculation
    
    /// Calculate overtraining risk from physiological markers
    static func calculateRisk(
        avgRecovery: Double?,        // Average recovery % last 7 days
        hrvDeviation: Double?,        // % deviation from baseline
        rhrElevation: Double?,        // % elevation from baseline
        tsb: Double?,                 // Training Stress Balance
        sleepDebt: Double?,           // Hours of sleep debt
        daysLowRecovery: Int          // Days with recovery <60%
    ) -> RiskResult {
        
        var riskFactors: [RiskFactor] = []
        var totalRisk: Double = 0
        var factorCount = 0
        
        // Factor 1: Low Recovery
        if let recovery = avgRecovery {
            let recoverySeverity: Double
            let recoveryDesc: String
            
            if recovery < 50 {
                recoverySeverity = 1.0
                recoveryDesc = "Critical: Recovery averaging \(Int(recovery))%"
            } else if recovery < 60 {
                recoverySeverity = 0.7
                recoveryDesc = "Poor: Recovery averaging \(Int(recovery))%"
            } else if recovery < 70 {
                recoverySeverity = 0.4
                recoveryDesc = "Fair: Recovery averaging \(Int(recovery))%"
            } else {
                recoverySeverity = 0.1
                recoveryDesc = "Good: Recovery averaging \(Int(recovery))%"
            }
            
            riskFactors.append(RiskFactor(
                name: "Recovery Score",
                severity: recoverySeverity,
                description: recoveryDesc
            ))
            totalRisk += recoverySeverity * 25
            factorCount += 1
        }
        
        // Factor 2: HRV Below Baseline
        if let hrv = hrvDeviation {
            let hrvSeverity: Double
            let hrvDesc: String
            
            if hrv < -20 {
                hrvSeverity = 1.0
                hrvDesc = "Critical: HRV \(Int(abs(hrv)))% below baseline"
            } else if hrv < -15 {
                hrvSeverity = 0.7
                hrvDesc = "High: HRV \(Int(abs(hrv)))% below baseline"
            } else if hrv < -10 {
                hrvSeverity = 0.4
                hrvDesc = "Moderate: HRV \(Int(abs(hrv)))% below baseline"
            } else {
                hrvSeverity = 0.1
                hrvDesc = "Normal: HRV within range"
            }
            
            riskFactors.append(RiskFactor(
                name: "HRV Deviation",
                severity: hrvSeverity,
                description: hrvDesc
            ))
            totalRisk += hrvSeverity * 25
            factorCount += 1
        }
        
        // Factor 3: Elevated RHR
        if let rhr = rhrElevation {
            let rhrSeverity: Double
            let rhrDesc: String
            
            if rhr > 15 {
                rhrSeverity = 1.0
                rhrDesc = "Critical: RHR +\(Int(rhr))% above baseline"
            } else if rhr > 10 {
                rhrSeverity = 0.7
                rhrDesc = "High: RHR +\(Int(rhr))% above baseline"
            } else if rhr > 5 {
                rhrSeverity = 0.4
                rhrDesc = "Moderate: RHR +\(Int(rhr))% above baseline"
            } else {
                rhrSeverity = 0.1
                rhrDesc = "Normal: RHR within range"
            }
            
            riskFactors.append(RiskFactor(
                name: "Resting Heart Rate",
                severity: rhrSeverity,
                description: rhrDesc
            ))
            totalRisk += rhrSeverity * 20
            factorCount += 1
        }
        
        // Factor 4: Training Stress Balance
        if let tsbValue = tsb {
            let tsbSeverity: Double
            let tsbDesc: String
            
            if tsbValue < -30 {
                tsbSeverity = 1.0
                tsbDesc = "Critical: TSB \(Int(tsbValue)) (severe overreaching)"
            } else if tsbValue < -20 {
                tsbSeverity = 0.7
                tsbDesc = "High: TSB \(Int(tsbValue)) (functional overreaching)"
            } else if tsbValue < -10 {
                tsbSeverity = 0.3
                tsbDesc = "Moderate: TSB \(Int(tsbValue)) (fatigued)"
            } else {
                tsbSeverity = 0.1
                tsbDesc = "Good: TSB \(Int(tsbValue)) (fresh or building)"
            }
            
            riskFactors.append(RiskFactor(
                name: "Training Stress Balance",
                severity: tsbSeverity,
                description: tsbDesc
            ))
            totalRisk += tsbSeverity * 20
            factorCount += 1
        }
        
        // Factor 5: Sleep Debt
        if let debt = sleepDebt {
            let sleepSeverity: Double
            let sleepDesc: String
            
            if debt > 10 {
                sleepSeverity = 1.0
                sleepDesc = "Critical: \(String(format: "%.1f", debt)) hours sleep debt"
            } else if debt > 6 {
                sleepSeverity = 0.6
                sleepDesc = "High: \(String(format: "%.1f", debt)) hours sleep debt"
            } else if debt > 3 {
                sleepSeverity = 0.3
                sleepDesc = "Moderate: \(String(format: "%.1f", debt)) hours sleep debt"
            } else {
                sleepSeverity = 0.1
                sleepDesc = "Low: \(String(format: "%.1f", debt)) hours sleep debt"
            }
            
            riskFactors.append(RiskFactor(
                name: "Sleep Debt",
                severity: sleepSeverity,
                description: sleepDesc
            ))
            totalRisk += sleepSeverity * 10
            factorCount += 1
        }
        
        // Calculate final risk score (0-100)
        let riskScore = factorCount > 0 ? min(totalRisk, 100) : 0
        
        // Determine risk level
        let riskLevel: RiskLevel
        if riskScore >= 75 {
            riskLevel = .critical
        } else if riskScore >= 50 {
            riskLevel = .high
        } else if riskScore >= 25 {
            riskLevel = .moderate
        } else {
            riskLevel = .low
        }
        
        // Generate recommendation
        let recommendation = generateRecommendation(
            riskLevel: riskLevel,
            riskScore: riskScore,
            factors: riskFactors
        )
        
        return RiskResult(
            riskScore: riskScore,
            riskLevel: riskLevel,
            factors: riskFactors,
            recommendation: recommendation
        )
    }
    
    // MARK: - Recommendations
    
    private static func generateRecommendation(
        riskLevel: RiskLevel,
        riskScore: Double,
        factors: [RiskFactor]
    ) -> String {
        switch riskLevel {
        case .low:
            return "Continue current training. Your body is adapting well to the workload."
            
        case .moderate:
            let topFactor = factors.max(by: { $0.severity < $1.severity })
            if let factor = topFactor {
                return "Monitor closely. Primary concern: \(factor.name). Consider 1-2 easier days."
            }
            return "Monitor recovery markers. Consider lighter training this week."
            
        case .high:
            return "High overtraining risk detected (\(Int(riskScore))/100). Take 3-5 recovery days with easy/no training. Prioritize sleep and nutrition."
            
        case .critical:
            return "CRITICAL: Immediate rest required. Take 5-7 days complete rest or very easy activity. If symptoms persist, consult a coach or doctor."
        }
    }
}
