import Foundation

/// Learn More content for Performance Metrics topics
extension LearnMoreContent {
    
    // MARK: - Training Load
    
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
                
                Think of CTL as your fitness bank account - the more you deposit through consistent training, the higher your balance.
                """
            ),
            Section(
                heading: "ATL - Fatigue",
                body: """
                Acute Training Load represents your short-term fatigue. It's a 7-day weighted average that shows recent training stress. High ATL means you're accumulating fatigue.
                
                ATL responds quickly to training changes, making it a good indicator of current fatigue levels.
                """
            ),
            Section(
                heading: "TSB - Form",
                body: """
                Training Stress Balance (TSB = CTL - ATL) indicates your readiness to perform. 
                
                • Positive TSB: You're fresh and ready to perform
                • Negative TSB: You're fatigued from recent training
                • Optimal race TSB: +5 to +25
                
                The key is timing your taper to peak at the right moment.
                """
            )
        ]
    )
    
    // MARK: - Intensity Factor
    
    static let intensityFactor = LearnMoreContent(
        title: "Intensity Factor",
        sections: [
            Section(
                heading: "What is Intensity Factor?",
                body: """
                Intensity Factor (IF) measures how hard a workout was relative to your threshold power (FTP). It's expressed as a decimal from 0 to 1.0+.
                
                IF = Normalized Power ÷ FTP
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
                
                A well-structured training plan uses a variety of IF values to develop different energy systems.
                """
            )
        ]
    )
    
    // MARK: - TSS
    
    static let tss = LearnMoreContent(
        title: "Training Stress Score (TSS)",
        sections: [
            Section(
                heading: "What is TSS?",
                body: """
                Training Stress Score quantifies the training load of a single workout. It accounts for both intensity and duration.
                
                TSS = (Duration × IF² × 100) ÷ 3600
                """
            ),
            Section(
                heading: "TSS Guidelines",
                body: """
                • <150 TSS: Low stress, easy recovery
                • 150-300 TSS: Medium stress, recovery needed
                • 300-450 TSS: High stress, significant recovery
                • >450 TSS: Very high stress, extended recovery
                
                Weekly TSS typically ranges from 300-800 depending on fitness level.
                """
            )
        ]
    )
    
    // MARK: - Normalized Power
    
    static let normalizedPower = LearnMoreContent(
        title: "Normalized Power",
        sections: [
            Section(
                heading: "What is Normalized Power?",
                body: """
                Normalized Power (NP) accounts for the variable nature of cycling power. Unlike average power, NP weighs harder efforts more heavily, providing a better representation of the physiological cost of a ride.
                """
            ),
            Section(
                heading: "Why Not Average Power?",
                body: """
                A ride with lots of intervals might have the same average power as a steady ride, but the intervals create much more fatigue. Normalized Power captures this difference.
                
                NP is always equal to or higher than average power, with the difference increasing as the ride becomes more variable.
                """
            )
        ]
    )
}
