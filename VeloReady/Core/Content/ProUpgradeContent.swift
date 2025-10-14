import Foundation

/// Content for Pro upgrade prompts throughout the app
struct ProUpgradeContent {
    let title: String
    let description: String
    let benefits: [Benefit]?
    
    struct Benefit {
        let icon: String
        let title: String
        let description: String
    }
    
    // MARK: - Workout Detail Upgrades
    
    static let trainingLoad = ProUpgradeContent(
        title: "Training Load Analysis",
        description: "Track your fitness, fatigue, and form with CTL, ATL, and TSB metrics over time.",
        benefits: nil
    )
    
    static let intensityAnalysis = ProUpgradeContent(
        title: "Ride Intensity Breakdown",
        description: "See exactly how hard you pushed with detailed intensity factor and zone distribution analysis.",
        benefits: nil
    )
    
    static let aiRideSummary = ProUpgradeContent(
        title: "AI Ride Analysis",
        description: "Get intelligent insights and personalized recommendations for every ride.",
        benefits: nil
    )
    
    // MARK: - Recovery Detail Upgrades
    
    static let weeklyRecoveryTrend = ProUpgradeContent(
        title: "Weekly Recovery Trends",
        description: "Track your recovery patterns over the past 7 days to optimize training timing.",
        benefits: nil
    )
    
    // MARK: - Strain Detail Upgrades
    
    static let weeklyStrainTrend = ProUpgradeContent(
        title: "Weekly Strain Analysis",
        description: "Monitor your training load over the past 7 days to prevent overtraining.",
        benefits: nil
    )
    
    // MARK: - Sleep Detail Upgrades
    
    static let weeklySleepTrend = ProUpgradeContent(
        title: "Weekly Sleep Patterns",
        description: "Understand your sleep quality trends to improve recovery and performance.",
        benefits: nil
    )
    
    // MARK: - Trends View Upgrades
    
    static let advancedTrends = ProUpgradeContent(
        title: "Advanced Performance Trends",
        description: "Unlock detailed analytics and long-term performance tracking.",
        benefits: nil
    )
    
    // MARK: - Training Zones Upgrades
    
    static let customTrainingZones = ProUpgradeContent(
        title: "Custom Training Zones",
        description: "Set personalized heart rate and power zones for more accurate training guidance.",
        benefits: nil
    )
    
    static let adaptiveZones = ProUpgradeContent(
        title: "Adaptive Zones",
        description: "A comprehensive, research-backed athlete profiling system that uses cutting-edge sports science to compute and adapt training zones from actual performance data.",
        benefits: [
            Benefit(
                icon: "cpu.fill",
                title: "Automatically Computed",
                description: "Zones calculated from your actual ride data"
            ),
            Benefit(
                icon: "chart.bar.doc.horizontal.fill",
                title: "Research-Backed",
                description: "Based on proven sports science algorithms"
            ),
            Benefit(
                icon: "arrow.triangle.2.circlepath",
                title: "Continuously Adapts",
                description: "Updates as your fitness changes over time"
            )
        ]
    )
}
