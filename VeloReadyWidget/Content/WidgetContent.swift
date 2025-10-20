//
//  WidgetContent.swift
//  VeloReadyWidget
//
//  Content strings for VeloReady widgets
//

import Foundation

enum WidgetContent {
    
    // MARK: - Widget Configuration
    
    enum Configuration {
        static let displayName = "VeloReady"
        static let description = "View your recovery score at a glance"
    }
    
    // MARK: - Ring Labels
    
    enum Labels {
        static let recovery = "Recovery"
        static let sleep = "Sleep"
        static let strain = "Strain"
    }
    
    // MARK: - Band Names
    
    enum RecoveryBands {
        static let optimal = "Optimal"
        static let good = "Good"
        static let fair = "Fair"
        static let poor = "Poor"
    }
    
    enum SleepBands {
        static let optimal = "Optimal"
        static let good = "Good"
        static let fair = "Fair"
        static let poor = "Poor"
    }
    
    enum StrainBands {
        static let light = "Light"
        static let moderate = "Moderate"
        static let high = "High"
        static let veryHigh = "Very High"
        static let allOut = "All Out"
    }
    
    // MARK: - Placeholder Text
    
    enum Placeholder {
        static let noData = "--"
        static let loading = "..."
    }
    
    // MARK: - Accessibility
    
    enum Accessibility {
        static let recoveryScore = "Recovery score"
        static let sleepScore = "Sleep score"
        static let strainScore = "Strain score"
        static let personalizedIndicator = "Personalized with machine learning"
    }
}
