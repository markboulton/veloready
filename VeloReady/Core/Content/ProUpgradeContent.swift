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
        description: "Science-backed algorithms combine your rides, strength training, and daily activities into a complete fitness picture.",
        benefits: nil
    )
    
    static let intensityAnalysis = ProUpgradeContent(
        title: "Ride Intensity Breakdown",
        description: "Understand how each ride impacts your overall training load alongside strength work and daily activities.",
        benefits: nil
    )
    
    static let aiRideSummary = ProUpgradeContent(
        title: "AI Ride Analysis",
        description: "AI-powered insights that consider your complete training picture - rides, strength, recovery, and sleep.",
        benefits: nil
    )
    
    static let advancedRideAnalytics = ProUpgradeContent(
        title: "Advanced Ride Analytics",
        description: "See how each ride fits into your complete training picture with holistic load analysis.",
        benefits: [
            Benefit(
                icon: "sparkles",
                title: "Holistic AI Analysis",
                description: "Insights that factor in rides, strength training, and daily activities"
            ),
            Benefit(
                icon: "chart.line.uptrend.xyaxis",
                title: "Complete Load Tracking",
                description: "37-day CTL/ATL/TSB trends combining all training modalities"
            ),
            Benefit(
                icon: "gauge.high",
                title: "Science-Backed Metrics",
                description: "Research-validated algorithms for accurate training stress"
            )
        ]
    )
    
    // MARK: - Recovery Detail Upgrades
    
    static let weeklyRecoveryTrend = ProUpgradeContent(
        title: "Weekly Recovery Trends",
        description: "Science-backed recovery tracking that factors in sleep, HRV, and total training load from all activities.",
        benefits: [
            Benefit(
                icon: "chart.line.uptrend.xyaxis",
                title: "Holistic Recovery Score",
                description: "Combines HRV, sleep, and training load for complete readiness"
            ),
            Benefit(
                icon: "heart.fill",
                title: "Research-Backed Metrics",
                description: "Science-validated algorithms track heart rate variability trends"
            ),
            Benefit(
                icon: "moon.fill",
                title: "Sleep Impact Analysis",
                description: "See how sleep quality affects recovery and training readiness"
            )
        ]
    )
    
    // MARK: - Load Detail Upgrades
    
    static let weeklyLoadTrend = ProUpgradeContent(
        title: "Weekly Load Analysis",
        description: "Complete training load picture combining rides, strength sessions, and daily activities with science-backed algorithms.",
        benefits: [
            Benefit(
                icon: "chart.bar.fill",
                title: "Holistic Load Tracking",
                description: "Combines cycling TSS, strength RPE, and daily activity into one score"
            ),
            Benefit(
                icon: "bicycle",
                title: "Multi-Modal Breakdown",
                description: "See how rides, strength training, and daily steps contribute to load"
            ),
            Benefit(
                icon: "exclamationmark.triangle.fill",
                title: "Science-Based Alerts",
                description: "Research-validated thresholds prevent overtraining across all activities"
            )
        ]
    )
    
    // MARK: - Sleep Detail Upgrades
    
    static let weeklySleepTrend = ProUpgradeContent(
        title: "Weekly Sleep Patterns",
        description: "See how sleep quality impacts recovery and training readiness with science-backed sleep stage analysis.",
        benefits: [
            Benefit(
                icon: "chart.line.uptrend.xyaxis",
                title: "Sleep-Recovery Connection",
                description: "Understand how sleep quality affects next-day training readiness"
            ),
            Benefit(
                icon: "bed.double.fill",
                title: "Research-Based Analysis",
                description: "Science-validated algorithms analyze deep, REM, and light sleep"
            ),
            Benefit(
                icon: "clock.fill",
                title: "Holistic Performance View",
                description: "See sleep patterns alongside training load and recovery trends"
            )
        ]
    )
    
    // MARK: - Trends View Upgrades
    
    static let advancedTrends = ProUpgradeContent(
        title: "Advanced Performance Trends",
        description: "Complete performance picture combining rides, strength training, recovery, and sleep with science-backed algorithms.",
        benefits: nil
    )
    
    // MARK: - Training Zones Upgrades
    
    static let customTrainingZones = ProUpgradeContent(
        title: "Custom Training Zones",
        description: "Personalized zones that adapt to your complete training picture - rides, strength work, and recovery status.",
        benefits: nil
    )
    
    static let adaptiveZones = ProUpgradeContent(
        title: "Adaptive Zones",
        description: "Research-backed zones that adapt to your complete training picture - rides, strength sessions, and recovery status.",
        benefits: [
            Benefit(
                icon: "cpu.fill",
                title: "Holistic Computation",
                description: "Zones calculated from rides, strength training, and recovery data"
            ),
            Benefit(
                icon: "chart.bar.doc.horizontal.fill",
                title: "Science-Validated",
                description: "Algorithms based on peer-reviewed sports science research"
            ),
            Benefit(
                icon: "arrow.triangle.2.circlepath",
                title: "Complete Adaptation",
                description: "Updates based on total training load across all activities"
            )
        ]
    )
    
    // MARK: - Today View Upgrades
    
    static let unlockProFeatures = ProUpgradeContent(
        title: "Unlock Pro Features",
        description: "Complete holistic health tracking - rides, strength training, and daily activities mapped with science-backed algorithms.",
        benefits: [
            Benefit(
                icon: "sparkles",
                title: "Holistic AI Analysis",
                description: "Insights combining rides, strength sessions, recovery, and sleep"
            ),
            Benefit(
                icon: "chart.line.uptrend.xyaxis",
                title: "Complete Load Tracking",
                description: "Science-backed CTL/ATL/TSB across all training modalities"
            ),
            Benefit(
                icon: "calendar",
                title: "Multi-Modal Trends",
                description: "7-day trends combining cycling, strength, recovery, and sleep"
            ),
            Benefit(
                icon: "gauge.high",
                title: "Research-Validated Metrics",
                description: "Peer-reviewed algorithms for accurate training stress"
            ),
            Benefit(
                icon: "cpu.fill",
                title: "Adaptive Intelligence",
                description: "Zones that adapt to your complete training picture"
            )
        ]
    )
}
