import Foundation

/// Content for Pro upgrade prompts throughout the app
struct ProUpgradeContent {
    let title: String
    let description: String
    let benefits: [String]?
    
    // MARK: - Workout Detail Upgrades
    
    static let trainingLoad = ProUpgradeContent(
        title: "Training Load Analysis",
        description: "Track your fitness, fatigue, and form with CTL, ATL, and TSB metrics over time.",
        benefits: [
            "37-day fitness trend visualization",
            "Understand training stress balance",
            "Optimize recovery and performance"
        ]
    )
    
    static let intensityAnalysis = ProUpgradeContent(
        title: "Ride Intensity Breakdown",
        description: "See exactly how hard you pushed with detailed intensity factor and zone distribution analysis.",
        benefits: [
            "Intensity factor tracking",
            "Training zone distribution",
            "Effort optimization insights"
        ]
    )
    
    static let aiRideSummary = ProUpgradeContent(
        title: "AI Ride Analysis",
        description: "Get intelligent insights and personalized recommendations for every ride.",
        benefits: [
            "AI-powered ride summaries",
            "Performance insights",
            "Training recommendations"
        ]
    )
    
    // MARK: - Recovery Detail Upgrades
    
    static let weeklyRecoveryTrend = ProUpgradeContent(
        title: "Weekly Recovery Trends",
        description: "Track your recovery patterns over the past 7 days to optimize training timing.",
        benefits: [
            "7-day recovery visualization",
            "Identify recovery patterns",
            "Plan training around readiness"
        ]
    )
    
    // MARK: - Strain Detail Upgrades
    
    static let weeklyStrainTrend = ProUpgradeContent(
        title: "Weekly Strain Analysis",
        description: "Monitor your training load over the past 7 days to prevent overtraining.",
        benefits: [
            "7-day strain tracking",
            "Overtraining prevention",
            "Load management insights"
        ]
    )
    
    // MARK: - Sleep Detail Upgrades
    
    static let weeklySleepTrend = ProUpgradeContent(
        title: "Weekly Sleep Patterns",
        description: "Understand your sleep quality trends to improve recovery and performance.",
        benefits: [
            "7-day sleep analysis",
            "Quality trend tracking",
            "Recovery optimization"
        ]
    )
    
    // MARK: - Trends View Upgrades
    
    static let advancedTrends = ProUpgradeContent(
        title: "Advanced Performance Trends",
        description: "Unlock detailed analytics and long-term performance tracking.",
        benefits: [
            "Extended historical data",
            "Advanced metrics",
            "Performance predictions"
        ]
    )
    
    // MARK: - Training Zones Upgrades
    
    static let customTrainingZones = ProUpgradeContent(
        title: "Custom Training Zones",
        description: "Set personalized heart rate and power zones for more accurate training guidance.",
        benefits: [
            "Personalized zone configuration",
            "Accurate training guidance",
            "Better performance tracking"
        ]
    )
    
    static let adaptiveZones = ProUpgradeContent(
        title: "Adaptive Zones",
        description: "A comprehensive, research-backed athlete profiling system that uses cutting-edge sports science to compute and adapt training zones from actual performance data.",
        benefits: [
            "Automatically computed from your rides",
            "Research-backed algorithms",
            "Adapts as your fitness changes"
        ]
    )
}
