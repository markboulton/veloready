import Foundation

/// Content structure for Learn More educational content
struct LearnMoreContent {
    let title: String
    let sections: [Section]
    
    struct Section {
        let heading: String?
        let body: String
    }
}

// MARK: - Learn More Content Library

extension LearnMoreContent {
    
    // MARK: - Training & Zones
    
    static let adaptiveZones = LearnMoreContent(
        title: "Adaptive Zones",
        sections: [
            Section(
                heading: "What are Adaptive Zones?",
                body: """
                Adaptive Zones are personalized training zones that automatically adjust based on your actual performance data. Unlike static zones that require manual updates, adaptive zones continuously evolve as your fitness changes.
                """
            ),
            Section(
                heading: "How They Work",
                body: """
                VeloReady analyzes your recent rides (last 120 days) using advanced sports science algorithms:
                
                • Critical Power Model - Determines your sustainable power output
                • Power Distribution Analysis - Identifies your performance curve
                • Heart Rate Lactate Threshold - Detects your LTHR from ride data
                • VO2max Estimation - Calculates aerobic capacity
                
                These algorithms work together to compute accurate zones without requiring lab testing.
                """
            ),
            Section(
                heading: "The Science",
                body: """
                Our adaptive zone system is based on peer-reviewed research in exercise physiology. The Critical Power model has been validated across thousands of athletes and provides more accurate training guidance than traditional percentage-based zones.
                
                By anchoring zones at your lactate threshold and adjusting for your unique physiology, adaptive zones ensure you're training at the right intensity for your current fitness level.
                """
            ),
            Section(
                heading: "Benefits",
                body: """
                • No Manual Updates - Zones adjust automatically as you get fitter
                • Personalized - Based on YOUR data, not generic formulas
                • Accurate - Uses multiple data points for precision
                • Research-Backed - Built on proven sports science
                • Comprehensive - Covers both heart rate and power zones
                """
            ),
            Section(
                heading: "What You'll See",
                body: """
                With adaptive zones, every ride shows:
                
                • Time spent in each training zone
                • Zone distribution pie charts
                • Intensity factor calculations
                • Training load metrics (CTL, ATL, TSB)
                • Personalized zone boundaries
                
                All automatically computed from your performance data.
                """
            )
        ]
    )
    
    // MARK: - Performance Metrics
    
    static let trainingLoad = LearnMoreContent(
        title: "Training Load",
        sections: [
            Section(
                heading: "Understanding Training Load",
                body: """
                Training load quantifies the stress your body experiences from training. VeloReady tracks three key metrics: CTL (Chronic Training Load), ATL (Acute Training Load), and TSB (Training Stress Balance).
                """
            ),
            Section(
                heading: "CTL - Fitness",
                body: """
                Chronic Training Load represents your long-term fitness. It's a 42-day weighted average of your daily training stress. As CTL increases, you're getting fitter.
                """
            ),
            Section(
                heading: "ATL - Fatigue",
                body: """
                Acute Training Load represents your short-term fatigue. It's a 7-day weighted average that shows recent training stress. High ATL means you're accumulating fatigue.
                """
            ),
            Section(
                heading: "TSB - Form",
                body: """
                Training Stress Balance (TSB = CTL - ATL) indicates your readiness to perform. Positive TSB means you're fresh, negative means you're fatigued. The sweet spot for racing is typically +5 to +25.
                """
            )
        ]
    )
    
    static let intensityFactor = LearnMoreContent(
        title: "Intensity Factor",
        sections: [
            Section(
                heading: "What is Intensity Factor?",
                body: """
                Intensity Factor (IF) measures how hard a workout was relative to your threshold power (FTP). It's expressed as a decimal from 0 to 1.0+.
                """
            ),
            Section(
                heading: "IF Ranges",
                body: """
                • 0.50-0.65 - Recovery rides
                • 0.65-0.75 - Endurance rides
                • 0.75-0.85 - Tempo rides
                • 0.85-0.95 - Threshold work
                • 0.95-1.05 - VO2max intervals
                • 1.05+ - Anaerobic efforts
                """
            ),
            Section(
                heading: "Why It Matters",
                body: """
                IF helps you understand if you're training at the right intensity for your goals. Combined with duration, it determines Training Stress Score (TSS) and helps prevent overtraining.
                """
            )
        ]
    )
}
