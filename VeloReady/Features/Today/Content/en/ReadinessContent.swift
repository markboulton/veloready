import Foundation

/// Content for Readiness Score feature
enum ReadinessContent {
    static let title = "Readiness"
    static let subtitle = "Ready to Train?"
    
    // MARK: - Bands
    enum Bands {
        static let fullyReady = "Fully Ready"
        static let ready = "Ready"
        static let compromised = "Compromised"
        static let notReady = "Not Ready"
    }
    
    // MARK: - Band Descriptions
    enum BandDescriptions {
        static let fullyReady = "Optimal readiness for training"
        static let ready = "Good readiness - moderate intensity safe"
        static let compromised = "Reduced readiness - easy training only"
        static let notReady = "Poor readiness - rest recommended"
    }
    
    // MARK: - Training Recommendations
    enum TrainingRecommendations {
        static let fullyReady = "High intensity training recommended"
        static let ready = "Moderate to high intensity safe"
        static let compromised = "Easy to moderate intensity only"
        static let notReady = "Rest day or very light activity"
    }
    
    // MARK: - Intensity Guidance
    enum IntensityGuidance {
        static let fullyReady = "Intervals, threshold work, or long rides"
        static let ready = "Tempo, endurance, or moderate intensity"
        static let compromised = "Easy spin, recovery ride, or light cross-training"
        static let notReady = "Complete rest or gentle stretching/walking"
    }
    
    // MARK: - Components
    enum Components {
        static let recovery = "Recovery"
        static let sleep = "Sleep"
        static let load = "Training Load"
    }
    
    // MARK: - Explanations
    static let explanation = "Readiness combines your recovery, sleep quality, and recent training load to provide a single actionable metric for training decisions."
    static let howCalculated = "Calculated from Recovery (40%), Sleep (35%), and Load Readiness (25%)"
}
