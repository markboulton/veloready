import Foundation

/// Statistical correlation calculator for trend analysis
struct CorrelationCalculator {
    
    // MARK: - Correlation Result
    
    struct CorrelationResult {
        let coefficient: Double  // Pearson's r (-1 to 1)
        let rSquared: Double     // R² (0 to 1)
        let sampleSize: Int
        let significance: Significance
        let trend: Trend
        
        enum Significance {
            case strong      // |r| >= 0.7
            case moderate    // |r| >= 0.5
            case weak        // |r| >= 0.3
            case none        // |r| < 0.3
            
            var description: String {
                switch self {
                case .strong: return "Strong"
                case .moderate: return "Moderate"
                case .weak: return "Weak"
                case .none: return "No"
                }
            }
        }
        
        enum Trend {
            case positive    // r > 0
            case negative    // r < 0
            case none        // r ≈ 0
        }
    }
    
    // MARK: - Pearson Correlation
    
    /// Calculate Pearson correlation coefficient between two variables
    /// - Parameters:
    ///   - x: First variable values
    ///   - y: Second variable values
    /// - Returns: Correlation result with coefficient, R², and significance
    static func pearsonCorrelation(x: [Double], y: [Double]) -> CorrelationResult? {
        // Validate inputs
        guard x.count == y.count, x.count >= 3 else {
            return nil
        }
        
        let n = Double(x.count)
        
        // Calculate means
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n
        
        // Calculate deviations and products
        var sumXY: Double = 0
        var sumX2: Double = 0
        var sumY2: Double = 0
        
        for i in 0..<x.count {
            let devX = x[i] - meanX
            let devY = y[i] - meanY
            
            sumXY += devX * devY
            sumX2 += devX * devX
            sumY2 += devY * devY
        }
        
        // Calculate correlation coefficient
        guard sumX2 > 0, sumY2 > 0 else {
            return nil  // Avoid division by zero
        }
        
        let r = sumXY / sqrt(sumX2 * sumY2)
        let rSquared = r * r
        
        // Determine significance
        let absR = abs(r)
        let significance: CorrelationResult.Significance
        if absR >= 0.7 {
            significance = .strong
        } else if absR >= 0.5 {
            significance = .moderate
        } else if absR >= 0.3 {
            significance = .weak
        } else {
            significance = .none
        }
        
        // Determine trend
        let trend: CorrelationResult.Trend
        if r > 0.1 {
            trend = .positive
        } else if r < -0.1 {
            trend = .negative
        } else {
            trend = .none
        }
        
        return CorrelationResult(
            coefficient: r,
            rSquared: rSquared,
            sampleSize: x.count,
            significance: significance,
            trend: trend
        )
    }
    
    // MARK: - Helper Methods
    
    /// Generate insight text from correlation result
    static func generateInsight(
        result: CorrelationResult,
        xName: String,
        yName: String,
        context: String? = nil
    ) -> String {
        let r = result.coefficient
        let percent = Int(abs(r) * 100)
        
        switch result.significance {
        case .strong:
            if r > 0 {
                return "\(result.significance.description) positive correlation (\(percent)%). Higher \(xName) strongly predicts higher \(yName)."
            } else {
                return "\(result.significance.description) negative correlation (\(percent)%). Higher \(xName) strongly predicts lower \(yName)."
            }
            
        case .moderate:
            if r > 0 {
                return "\(result.significance.description) correlation (\(percent)%). \(xName) has a noticeable positive effect on \(yName)."
            } else {
                return "\(result.significance.description) correlation (\(percent)%). \(xName) has a noticeable negative effect on \(yName)."
            }
            
        case .weak:
            return "Weak correlation (\(percent)%). \(xName) has minimal impact on \(yName)."
            
        case .none:
            return "No significant correlation. \(xName) and \(yName) appear independent."
        }
    }
    
    /// Format correlation coefficient for display
    static func formatCoefficient(_ r: Double) -> String {
        return String(format: "%.2f", r)
    }
    
    /// Format R² for display
    static func formatRSquared(_ rSquared: Double) -> String {
        return String(format: "%.2f", rSquared)
    }
}
