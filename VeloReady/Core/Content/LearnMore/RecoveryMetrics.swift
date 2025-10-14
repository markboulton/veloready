import Foundation

/// Learn More content for Recovery Metrics topics
extension LearnMoreContent {
    
    // MARK: - Recovery Score
    
    static let recoveryScore = LearnMoreContent(
        title: "Recovery Score",
        sections: [
            Section(
                heading: "What is Recovery Score?",
                body: """
                Your Recovery Score indicates how well your body has recovered from recent training and how ready you are for another hard workout.
                
                It combines sleep quality, resting heart rate, and heart rate variability into a single 0-100% score.
                """
            ),
            Section(
                heading: "Score Interpretation",
                body: """
                • 80-100%: Excellent recovery, ready for hard training
                • 60-79%: Good recovery, moderate training recommended
                • 40-59%: Fair recovery, easy training or rest
                • 20-39%: Poor recovery, rest recommended
                • 0-19%: Very poor recovery, rest required
                """
            ),
            Section(
                heading: "What Affects It?",
                body: """
                Your recovery score is influenced by:
                
                • Sleep duration and quality
                • Resting heart rate trends
                • Heart rate variability (HRV)
                • Recent training load
                • Stress and lifestyle factors
                
                Consistent sleep and recovery practices lead to better scores.
                """
            )
        ]
    )
    
    // MARK: - HRV
    
    static let hrv = LearnMoreContent(
        title: "Heart Rate Variability (HRV)",
        sections: [
            Section(
                heading: "What is HRV?",
                body: """
                Heart Rate Variability measures the variation in time between heartbeats. Higher HRV generally indicates better recovery and readiness to train.
                
                HRV is controlled by your autonomic nervous system and reflects the balance between stress and recovery.
                """
            ),
            Section(
                heading: "Understanding Your HRV",
                body: """
                HRV is highly individual - what matters is YOUR trend, not comparison to others.
                
                • Rising HRV: Good recovery, body adapting well
                • Stable HRV: Maintaining current fitness
                • Falling HRV: Accumulating fatigue, may need rest
                
                Track your baseline over weeks to understand your patterns.
                """
            )
        ]
    )
    
    // MARK: - Resting Heart Rate
    
    static let restingHeartRate = LearnMoreContent(
        title: "Resting Heart Rate",
        sections: [
            Section(
                heading: "What is Resting Heart Rate?",
                body: """
                Your resting heart rate (RHR) is the number of times your heart beats per minute when you're completely at rest, typically measured first thing in the morning.
                """
            ),
            Section(
                heading: "What It Tells You",
                body: """
                • Lower RHR: Generally indicates better cardiovascular fitness
                • Rising RHR: May indicate fatigue, illness, or overtraining
                • Stable RHR: Good recovery and adaptation
                
                An elevated RHR (5-10 bpm above normal) is a strong signal to take an easy day or rest.
                """
            )
        ]
    )
}
