import Foundation
import Combine

/// Service for predicting future readiness based on current trends
@MainActor
class ReadinessForecastService: ObservableObject {
    static let shared = ReadinessForecastService()
    
    @Published var forecast: [ReadinessForecast] = []  /// 7-day forecast
    @Published var isLoading = false  /// Loading state
    @Published var lastError: String?  /// Last error message
    
    private let recoveryService = RecoveryScoreService.shared
    private let sleepService = SleepScoreService.shared
    private let strainService = StrainScoreService.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Generate 7-day readiness forecast
    func generateForecast() async {
        isLoading = true
        lastError = nil
        
        guard let currentRecovery = recoveryService.currentRecoveryScore else {
            lastError = "No recovery data available"
            isLoading = false
            return
        }
        
        // Get current metrics
        let currentHRV = currentRecovery.inputs.hrv ?? 0
        let baselineHRV = currentRecovery.inputs.hrvBaseline ?? currentHRV
        let currentRHR = currentRecovery.inputs.rhr ?? 0
        let baselineRHR = currentRecovery.inputs.rhrBaseline ?? currentRHR
        let currentCTL = currentRecovery.inputs.ctl ?? 0
        let currentATL = currentRecovery.inputs.atl ?? 0
        let currentTSB = currentCTL - currentATL
        
        var forecasts: [ReadinessForecast] = []
        
        // Generate 7-day forecast
        for day in 1...7 {
            let forecastDate = Calendar.current.date(byAdding: .day, value: day, to: Date())!
            
            // Predict metrics based on trends
            let predictedRecovery = predictRecovery(
                day: day,
                currentHRV: currentHRV,
                baselineHRV: baselineHRV,
                currentRHR: currentRHR,
                baselineRHR: baselineRHR,
                currentTSB: currentTSB
            )
            
            let predictedReadiness = calculateReadiness(
                recovery: predictedRecovery,
                tsb: currentTSB,
                day: day
            )
            
            let recommendation = generateRecommendation(
                readiness: predictedReadiness,
                recovery: predictedRecovery,
                day: day
            )
            
            forecasts.append(ReadinessForecast(
                date: forecastDate,
                predictedRecovery: predictedRecovery,
                predictedReadiness: predictedReadiness,
                confidence: calculateConfidence(day: day),
                recommendation: recommendation
            ))
        }
        
        self.forecast = forecasts
        isLoading = false
    }
    
    /// Get forecast summary
    func getForecastSummary() -> ForecastSummary? {
        guard !forecast.isEmpty else { return nil }
        
        let avgReadiness = forecast.map(\.predictedReadiness).reduce(0, +) / Double(forecast.count)
        let peakDay = forecast.max(by: { $0.predictedReadiness < $1.predictedReadiness })
        let lowDay = forecast.min(by: { $0.predictedReadiness < $1.predictedReadiness })
        
        return ForecastSummary(
            averageReadiness: avgReadiness,
            peakDay: peakDay,
            lowDay: lowDay,
            trend: determineTrend(forecast)
        )
    }
    
    // MARK: - Private Methods
    
    private func predictRecovery(
        day: Int,
        currentHRV: Double,
        baselineHRV: Double,
        currentRHR: Double,
        baselineRHR: Double,
        currentTSB: Double
    ) -> Double {
        // Simple linear regression model
        // Assumes gradual return to baseline with rest
        
        let hrvRatio = currentHRV / max(baselineHRV, 1)
        let rhrRatio = baselineRHR / max(currentRHR, 1)
        
        // If well-recovered, maintain; if fatigued, gradual improvement
        let hrvTrend = hrvRatio < 0.95 ? 0.02 * Double(day) : 0  // 2% improvement per day if low
        let rhrTrend = rhrRatio < 0.95 ? 0.02 * Double(day) : 0  // 2% improvement per day if high
        
        // TSB influence (positive TSB = fresh, negative = fatigued)
        let tsbInfluence = currentTSB > 0 ? 5.0 : -5.0
        
        // Calculate predicted recovery score
        let baseScore = (hrvRatio + rhrTrend) * 50 + (rhrRatio + rhrTrend) * 30 + tsbInfluence
        
        // Clamp between 0-100
        return min(100, max(0, baseScore))
    }
    
    private func calculateReadiness(recovery: Double, tsb: Double, day: Int) -> Double {
        // Readiness combines recovery with training stress balance
        // High recovery + positive TSB = high readiness
        // Low recovery or negative TSB = low readiness
        
        let tsbFactor = tsb > 0 ? 1.1 : 0.9  // Boost if fresh, reduce if fatigued
        let dayFactor = 1.0 - (Double(day) * 0.02)  // Confidence decreases with forecast distance
        
        let readiness = recovery * tsbFactor * dayFactor
        
        return min(100, max(0, readiness))
    }
    
    private func calculateConfidence(day: Int) -> Double {
        // Confidence decreases with forecast distance
        // Day 1: 90%, Day 7: 50%
        return max(50, 90 - (Double(day) * 6))
    }
    
    private func generateRecommendation(readiness: Double, recovery: Double, day: Int) -> String {
        let dayName = getDayName(daysFromNow: day)
        
        switch readiness {
        case 80...:
            return "\(dayName): Excellent readiness. Good day for hard training or racing."
        case 60..<80:
            return "\(dayName): Good readiness. Moderate to hard training recommended."
        case 40..<60:
            return "\(dayName): Fair readiness. Consider easy training or active recovery."
        default:
            return "\(dayName): Low readiness. Rest or very light activity recommended."
        }
    }
    
    private func getDayName(daysFromNow: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func determineTrend(_ forecasts: [ReadinessForecast]) -> String {
        guard forecasts.count >= 2 else { return "Stable" }
        
        let first = forecasts.prefix(3).map(\.predictedReadiness).reduce(0, +) / 3
        let last = forecasts.suffix(3).map(\.predictedReadiness).reduce(0, +) / 3
        
        let change = last - first
        
        if change > 5 {
            return "Improving"
        } else if change < -5 {
            return "Declining"
        } else {
            return "Stable"
        }
    }
}

// MARK: - Data Models

struct ReadinessForecast: Identifiable {
    let id = UUID()
    let date: Date  /// Forecast date
    let predictedRecovery: Double  /// Predicted recovery score (0-100)
    let predictedReadiness: Double  /// Predicted readiness score (0-100)
    let confidence: Double  /// Confidence level (0-100)
    let recommendation: String  /// Training recommendation
}

struct ForecastSummary {
    let averageReadiness: Double  /// Average readiness over forecast period
    let peakDay: ReadinessForecast?  /// Best day for hard training
    let lowDay: ReadinessForecast?  /// Day requiring most recovery
    let trend: String  /// Overall trend direction
}
