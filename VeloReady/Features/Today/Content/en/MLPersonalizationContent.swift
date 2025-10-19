import Foundation

/// Content strings for ML Personalization information
enum MLPersonalizationContent {
    // MARK: - Header
    static let title = "Personalized Insights"
    static let subtitle = "Your Recovery Score, Tailored to You"
    
    // MARK: - What Is It
    static let whatIsItTitle = "Why Personalization Matters"
    static let whatIsItBody = """
Every athlete is different. Some recover faster on Mondays, others need more sleep to feel ready. Generic algorithms can't capture what makes you unique.

VeloReady learns your patterns over time, so your Recovery Score reflects YOUR body—not an average athlete.
"""
    
    // MARK: - How It Works
    static let howItWorksTitle = "How It Works"
    static let howItWorksBody = """
Over the next few weeks, VeloReady quietly observes your patterns:

• **Your Baselines**: How your HRV, heart rate, and sleep naturally fluctuate
• **Your Rhythms**: Whether you're a Monday warrior or weekend recoverer
• **Your Response**: How training load affects your recovery uniquely

Once we have 30 days of data, we'll start personalizing your insights—no action needed from you.
"""
    
    // MARK: - What We Learn
    static let whatWeLearnTitle = "What We're Learning"
    static let whatWeLearnBody = """
VeloReady tracks patterns in your:

• **Recovery Metrics**: HRV, resting heart rate, and sleep quality
• **Training Load**: How your body responds to different workout intensities
• **Weekly Patterns**: Day-of-week trends and training cycles
• **Sleep Needs**: Your personal sleep requirements vs. averages

All processing happens on your device—your data never leaves your phone.
"""
    
    // MARK: - Privacy
    static let privacyTitle = "Your Data, Your Device"
    static let privacyBody = """
Privacy is built into the core of VeloReady:

• **On-Device Learning**: All personalization happens locally on your iPhone
• **No Cloud Processing**: Your patterns never leave your device
• **iCloud Sync Only**: If enabled, encrypted data syncs only to your personal iCloud
• **You're in Control**: Disable personalization anytime in Settings

We don't see your data. We don't train models on your data. It's yours, period.
"""
    
    // MARK: - What Changes
    static let whatChangesTitle = "What Changes When Ready"
    static let whatChangesBody = """
Once personalization activates, you'll see:

• **Context-Aware Baselines**: "Your Monday baseline" instead of generic averages
• **Smarter Predictions**: Recovery scores that understand YOUR patterns
• **Better Recommendations**: Training advice based on how you actually respond

The app will feel the same—just more accurate for you.
"""
    
    // MARK: - Actions
    static let closeButton = "Got it"
    static let learnMore = "Learn More"
}
