import Foundation
import Combine

/// Service for analyzing correlation between recovery and sleep metrics
@MainActor
class RecoverySleepCorrelationService: ObservableObject {
    static let shared = RecoverySleepCorrelationService()
    
    @Published var correlationData: CorrelationData?  /// Correlation analysis results
    @Published var insights: [CorrelationInsight] = []  /// Key insights
    @Published var isLoading = false  /// Loading state
    @Published var lastError: String?  /// Last error message
    
    private let recoveryService = RecoveryScoreService.shared
    private let sleepService = SleepScoreService.shared
    private let cacheKey = "correlation_cache"
    private let cacheDuration: TimeInterval = 3600 // 1 hour
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Analyze correlation between recovery and sleep over specified period
    func analyzeCorrelation(days: Int = 30) async {
        isLoading = true
        lastError = nil
        
        // Check cache first
        if let cached = loadFromCache(), cached.timestamp.timeIntervalSinceNow > -cacheDuration {
            self.correlationData = cached.data
            self.insights = cached.insights
            isLoading = false
            return
        }
        
        // Get historical data (would need to implement historical tracking)
        // For now, using current scores as example
        guard let currentRecovery = recoveryService.currentRecoveryScore,
              let currentSleep = sleepService.currentSleepScore else {
            lastError = "Insufficient data for correlation analysis"
            isLoading = false
            return
        }
        
        // TODO: Implement historical data fetching
        // For now, generate sample correlation data
        let correlation = calculateCorrelation(
            recoveryScores: [Double(currentRecovery.score)],
            sleepScores: [Double(currentSleep.score)]
        )
        
        let data = CorrelationData(
            correlationCoefficient: correlation,
            sampleSize: 1,
            significance: determineSignificance(correlation, sampleSize: 1),
            scatterData: []  // Would populate with historical data
        )
        
        let insights = generateInsights(data)
        
        self.correlationData = data
        self.insights = insights
        
        // Cache results
        saveToCache(CachedCorrelationData(data: data, insights: insights, timestamp: Date()))
        
        isLoading = false
    }
    
    /// Get correlation summary
    func getCorrelationSummary() -> String {
        guard let data = correlationData else {
            return "No correlation data available"
        }
        
        let strength = getCorrelationStrength(data.correlationCoefficient)
        let direction = data.correlationCoefficient >= 0 ? "positive" : "negative"
        
        return "There is a \(strength) \(direction) correlation between your sleep quality and recovery scores."
    }
    
    // MARK: - Private Methods
    
    private func calculateCorrelation(recoveryScores: [Double], sleepScores: [Double]) -> Double {
        guard recoveryScores.count == sleepScores.count, recoveryScores.count > 1 else {
            return 0
        }
        
        let n = Double(recoveryScores.count)
        
        // Calculate means
        let meanRecovery = recoveryScores.reduce(0, +) / n
        let meanSleep = sleepScores.reduce(0, +) / n
        
        // Calculate correlation coefficient (Pearson's r)
        var numerator: Double = 0
        var sumRecoverySquared: Double = 0
        var sumSleepSquared: Double = 0
        
        for i in 0..<recoveryScores.count {
            let recoveryDiff = recoveryScores[i] - meanRecovery
            let sleepDiff = sleepScores[i] - meanSleep
            
            numerator += recoveryDiff * sleepDiff
            sumRecoverySquared += recoveryDiff * recoveryDiff
            sumSleepSquared += sleepDiff * sleepDiff
        }
        
        let denominator = sqrt(sumRecoverySquared * sumSleepSquared)
        
        guard denominator > 0 else { return 0 }
        
        return numerator / denominator
    }
    
    private func determineSignificance(_ correlation: Double, sampleSize: Int) -> CorrelationSignificance {
        // Simple significance test based on sample size and correlation strength
        let absCorrelation = abs(correlation)
        
        if sampleSize < 10 {
            return .insufficient
        } else if absCorrelation > 0.7 && sampleSize >= 30 {
            return .strong
        } else if absCorrelation > 0.5 && sampleSize >= 20 {
            return .moderate
        } else if absCorrelation > 0.3 && sampleSize >= 15 {
            return .weak
        } else {
            return .none
        }
    }
    
    private func getCorrelationStrength(_ coefficient: Double) -> String {
        let abs = abs(coefficient)
        
        switch abs {
        case 0.7...:
            return "strong"
        case 0.5..<0.7:
            return "moderate"
        case 0.3..<0.5:
            return "weak"
        default:
            return "negligible"
        }
    }
    
    private func generateInsights(_ data: CorrelationData) -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []
        
        let coefficient = data.correlationCoefficient
        
        // Insight 1: Overall correlation
        if abs(coefficient) > 0.5 {
            insights.append(CorrelationInsight(
                title: "Strong Sleep-Recovery Link",
                description: "Your recovery scores are significantly influenced by sleep quality. Prioritizing sleep will directly improve recovery.",
                priority: .high,
                icon: "moon.stars.fill"
            ))
        } else if abs(coefficient) > 0.3 {
            insights.append(CorrelationInsight(
                title: "Moderate Sleep Impact",
                description: "Sleep quality has a noticeable effect on recovery. Consider improving sleep consistency.",
                priority: .medium,
                icon: "moon.fill"
            ))
        } else {
            insights.append(CorrelationInsight(
                title: "Multiple Recovery Factors",
                description: "Your recovery is influenced by multiple factors beyond sleep. Consider training load and stress management.",
                priority: .low,
                icon: "chart.line.uptrend.xyaxis"
            ))
        }
        
        // Insight 2: Actionable recommendation
        if coefficient > 0.5 {
            insights.append(CorrelationInsight(
                title: "Sleep Optimization Priority",
                description: "Focus on achieving your sleep target consistently. Each hour of quality sleep significantly boosts recovery.",
                priority: .high,
                icon: "target"
            ))
        }
        
        // Insight 3: Data quality
        if data.sampleSize < 14 {
            insights.append(CorrelationInsight(
                title: "More Data Needed",
                description: "Continue tracking for at least 2 weeks to get more accurate correlation insights.",
                priority: .low,
                icon: "calendar"
            ))
        }
        
        return insights
    }
    
    private func saveToCache(_ data: CachedCorrelationData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadFromCache() -> CachedCorrelationData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(CachedCorrelationData.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// MARK: - Data Models

struct CorrelationData: Codable {
    let correlationCoefficient: Double  /// Pearson correlation coefficient (-1 to 1)
    let sampleSize: Int  /// Number of data points
    let significance: CorrelationSignificance  /// Statistical significance
    let scatterData: [CorrelationPoint]  /// Data points for scatter plot
}

struct CorrelationPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date  /// Date of measurement
    let recoveryScore: Double  /// Recovery score
    let sleepScore: Double  /// Sleep score
    
    enum CodingKeys: String, CodingKey {
        case date, recoveryScore, sleepScore
    }
}

struct CorrelationInsight: Identifiable, Codable {
    let id = UUID()
    let title: String  /// Insight title
    let description: String  /// Detailed description
    let priority: InsightPriority  /// Priority level
    let icon: String  /// SF Symbol icon name
    
    enum CodingKeys: String, CodingKey {
        case title, description, priority, icon
    }
}

enum CorrelationSignificance: String, Codable {
    case strong = "Strong"  /// Statistically significant, strong correlation
    case moderate = "Moderate"  /// Statistically significant, moderate correlation
    case weak = "Weak"  /// Weak but detectable correlation
    case none = "None"  /// No significant correlation
    case insufficient = "Insufficient Data"  /// Not enough data
}

enum InsightPriority: String, Codable {
    case high = "High"  /// High priority insight
    case medium = "Medium"  /// Medium priority insight
    case low = "Low"  /// Low priority insight
}

private struct CachedCorrelationData: Codable {
    let data: CorrelationData  /// Cached correlation data
    let insights: [CorrelationInsight]  /// Cached insights
    let timestamp: Date  /// Cache timestamp
}
