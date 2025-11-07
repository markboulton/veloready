import Foundation
import HealthKit

/// Enhanced illness detection service with ML-based pattern recognition and caching
/// Detects potential body stress signals through multi-day physiological trend analysis
/// DISCLAIMER: This is NOT medical advice - it's a wellness awareness tool
@MainActor
class IllnessDetectionService: ObservableObject {
    static let shared = IllnessDetectionService()
    
    @Published var currentIndicator: IllnessIndicator?
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    
    private let calculator = IllnessDetectionCalculator()
    private let cacheManager = UnifiedCacheManager.shared
    
    // Analysis configuration
    private let minimumAnalysisInterval: TimeInterval = 3600 // 1 hour between analyses
    
    private init() {}
    
    // MARK: - Public API
    
    /// Analyze recent health trends for potential illness indicators
    /// Uses caching to avoid redundant calculations
    func analyzeHealthTrends(forceRefresh: Bool = false) async {
        // Debug mode: show mock illness indicator
        #if DEBUG
        if ProFeatureConfig.shared.showIllnessIndicatorForTesting {
            Logger.debug("🧪 DEBUG: Showing mock illness indicator")
            currentIndicator = IllnessIndicator(
                date: Date(),
                severity: .moderate,
                confidence: 0.78,
                signals: [
                    IllnessIndicator.Signal(
                        type: .elevatedRHR,
                        deviation: 8.5,
                        value: 62.0,
                        baseline: 57.1
                    ),
                    IllnessIndicator.Signal(
                        type: .hrvDrop,
                        deviation: -18.2,
                        value: 42.5,
                        baseline: 52.0
                    )
                ],
                recommendation: "Take it easy with training - light activity or rest"
            )
            lastAnalysisDate = Date()
            return
        }
        #endif
        guard !isAnalyzing else {
            Logger.debug("🔍 Illness analysis already in progress, skipping...")
            return
        }
        
        // Check if we've analyzed recently (unless force refresh)
        if !forceRefresh, let lastAnalysis = lastAnalysisDate {
            let timeSinceLastAnalysis = Date().timeIntervalSince(lastAnalysis)
            if timeSinceLastAnalysis < minimumAnalysisInterval {
                Logger.debug("⏰ Illness analysis ran \(Int(timeSinceLastAnalysis/60))m ago, skipping")
                return
            }
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        Logger.debug("🔍 Starting illness detection analysis...")
        
        // Try to fetch from cache first
        let cacheKey = CacheKey.illnessDetection(date: Date())
        
        do {
            let indicator = try await cacheManager.fetch(
                key: cacheKey,
                ttl: UnifiedCacheManager.CacheTTL.wellness
            ) {
                // Cache miss - delegate to calculator (runs on background thread)
                return await self.calculator.performAnalysis()
            }
            
            currentIndicator = indicator
            lastAnalysisDate = Date()
            
            if let indicator = indicator {
                Logger.warning("⚠️ ILLNESS INDICATOR: \(indicator.severity.rawValue) - \(indicator.confidence * 100)% confidence")
            } else {
                Logger.debug("✅ No illness indicators detected")
            }
            
        } catch {
            Logger.error("❌ Illness detection failed: \(error.localizedDescription)")
            currentIndicator = nil
        }
    }
    
    /// Clear cached illness detection results
    func clearCache() async {
        let cacheKey = CacheKey.illnessDetection(date: Date())
        await cacheManager.invalidate(key: cacheKey)
        Logger.debug("🗑️ Cleared illness detection cache")
    }
}
