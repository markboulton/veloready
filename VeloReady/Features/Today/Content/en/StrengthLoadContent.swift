import Foundation

/// Content strings for Strength Training Load information
enum StrengthLoadContent {
    // MARK: - Header
    static let title = "Training Load"
    static let subtitle = "Understanding Your Workout Intensity"
    
    // MARK: - What Is It
    static let whatIsItTitle = "What is Training Load?"
    static let whatIsItBody = """
Training Load quantifies how demanding your strength workout was on your body. It combines your effort level (RPE), workout duration, and the muscle groups you trained to give you a single number that represents the physiological stress of your session.

Think of it as a way to compare workouts: a 30-minute light upper body session will have a much lower load than a 60-minute heavy leg day.
"""
    
    // MARK: - How It Works
    static let howItWorksTitle = "How We Calculate It"
    static let howItWorksBody = """
We use a research-backed formula that factors in:

• **Effort Level (RPE)**: How hard the workout felt to you
• **Duration**: How long you trained
• **Muscle Groups**: Larger muscles (like legs) create more systemic fatigue
• **Workout Type**: Compound movements (like full body workouts) demand more from your system

The score is simplified to a 0-100+ scale for easy interpretation.
"""
    
    // MARK: - Intensity Levels
    static let intensityLevelsTitle = "Intensity Levels"
    static let lightLabel = "Light (0-15)"
    static let lightDescription = "Easy recovery sessions or skill work"
    static let moderateLabel = "Moderate (15-30)"
    static let moderateDescription = "Standard training sessions with good volume"
    static let hardLabel = "Hard (30-45)"
    static let hardDescription = "Challenging sessions that require recovery"
    static let veryHardLabel = "Very Hard (45+)"
    static let veryHardDescription = "Maximum effort sessions - plan adequate recovery"
    
    // MARK: - Why It Matters
    static let whyItMattersTitle = "Why It Matters"
    static let whyItMattersBody = """
Training Load helps you:

• **Track Progress**: See how your training intensity evolves over time
• **Balance Training**: Avoid overtraining by monitoring cumulative load
• **Plan Recovery**: Higher loads require more recovery time
• **Compare Workouts**: Understand which sessions are most demanding

Your Training Load feeds into your Recovery Score, helping you make smarter training decisions.
"""
    
    // MARK: - Actions
    static let closeButton = "Got it"
}
