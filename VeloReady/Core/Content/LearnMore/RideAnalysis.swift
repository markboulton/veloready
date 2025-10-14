import Foundation

/// Learn More content for Ride Analysis features
extension LearnMoreContent {
    
    // MARK: - AI Ride Analysis
    
    static let aiRideAnalysis = LearnMoreContent(
        title: "AI Ride Analysis",
        sections: [
            Section(
                heading: "What is AI Ride Analysis?",
                body: """
                AI Ride Analysis uses advanced machine learning to automatically analyze your rides and provide personalized insights, recommendations, and performance summaries.
                
                Instead of manually reviewing your data, our AI identifies patterns, highlights key moments, and suggests actionable improvements.
                """
            ),
            Section(
                heading: "How It Works",
                body: """
                After each ride, our AI system:
                
                • Analyzes your power, heart rate, and cadence data
                • Identifies key efforts and intervals
                • Compares performance to your historical data
                • Detects training patterns and trends
                • Generates natural language summaries
                
                The analysis happens automatically within minutes of completing your ride.
                """
            ),
            Section(
                heading: "What You'll Learn",
                body: """
                Each AI summary includes:
                
                • Ride Overview - Key stats and overall assessment
                • Performance Highlights - Best efforts and achievements
                • Training Insights - What the ride accomplished
                • Recovery Recommendations - How to optimize rest
                • Future Suggestions - What to focus on next
                
                All written in clear, actionable language.
                """
            ),
            Section(
                heading: "Personalization",
                body: """
                The AI learns from your data over time. As you complete more rides, the analysis becomes increasingly personalized to your:
                
                • Fitness level and capabilities
                • Training goals and patterns
                • Strengths and areas for improvement
                • Response to different training stimuli
                
                No two athletes get the same analysis.
                """
            )
        ]
    )
    
    // MARK: - Advanced Ride Analytics
    
    static let advancedRideAnalytics = LearnMoreContent(
        title: "Advanced Ride Analytics",
        sections: [
            Section(
                heading: "Three Powerful Tools",
                body: """
                Advanced Ride Analytics combines three essential analysis tools to give you complete insight into every ride: AI Analysis, Training Load Tracking, and Intensity Breakdown.
                
                Together, these tools answer the key questions: How hard was it? What did it accomplish? What should I do next?
                """
            ),
            Section(
                heading: "AI Ride Analysis",
                body: """
                Get intelligent insights and personalized recommendations for every ride. Our AI analyzes your performance data and generates natural language summaries that highlight key efforts, identify patterns, and suggest improvements.
                
                No more staring at charts wondering what it all means - the AI tells you exactly what happened and why it matters.
                """
            ),
            Section(
                heading: "Training Load Tracking",
                body: """
                Monitor your fitness, fatigue, and form with 37-day CTL/ATL/TSB trends. See how each ride impacts your long-term fitness (CTL), short-term fatigue (ATL), and readiness to perform (TSB).
                
                The training load chart shows past performance and projects future trends, helping you time your peak perfectly.
                """
            ),
            Section(
                heading: "Intensity Breakdown",
                body: """
                Analyze effort distribution and intensity factor for optimal training. See exactly how hard you pushed with detailed zone distribution, intensity factor calculations, and comparison to your threshold.
                
                Understand whether you're training at the right intensity for your goals and make adjustments accordingly.
                """
            ),
            Section(
                heading: "Why All Three Matter",
                body: """
                Each tool provides a different perspective:
                
                • AI Analysis - What happened and what it means
                • Training Load - How it fits into your bigger picture
                • Intensity - Whether you hit the right effort level
                
                Together, they give you complete understanding of every ride and how to improve.
                """
            )
        ]
    )
}
