import Foundation

/// Learn More content for Training Zones topics
extension LearnMoreContent {
    
    // MARK: - Adaptive Zones
    
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
    
    // MARK: - Heart Rate Zones
    
    static let heartRateZones = LearnMoreContent(
        title: "Heart Rate Zones",
        sections: [
            Section(
                heading: "Understanding HR Zones",
                body: """
                Heart rate zones divide your cardiovascular capacity into distinct training intensities. Each zone targets specific physiological adaptations.
                """
            ),
            Section(
                heading: "The Seven Zones",
                body: """
                Zone 1 (Recovery): 50-60% of max HR - Active recovery
                Zone 2 (Endurance): 60-70% - Aerobic base building
                Zone 3 (Tempo): 70-80% - Sustained aerobic work
                Zone 4 (Threshold): 80-90% - Lactate threshold training
                Zone 5 (VO2max): 90-95% - Maximum aerobic capacity
                Zone 6 (Anaerobic): 95-100% - Anaerobic capacity
                Zone 7 (Neuromuscular): 100%+ - Sprint power
                """
            )
        ]
    )
    
    // MARK: - Power Zones
    
    static let powerZones = LearnMoreContent(
        title: "Power Zones",
        sections: [
            Section(
                heading: "Understanding Power Zones",
                body: """
                Power zones are based on your Functional Threshold Power (FTP) - the maximum power you can sustain for one hour.
                """
            ),
            Section(
                heading: "The Seven Zones",
                body: """
                Zone 1 (Active Recovery): <55% FTP
                Zone 2 (Endurance): 55-75% FTP
                Zone 3 (Tempo): 75-90% FTP
                Zone 4 (Lactate Threshold): 90-105% FTP
                Zone 5 (VO2max): 105-120% FTP
                Zone 6 (Anaerobic Capacity): 120-150% FTP
                Zone 7 (Neuromuscular Power): >150% FTP
                """
            )
        ]
    )
}
