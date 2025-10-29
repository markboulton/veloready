import Foundation

// This is a placeholder for core business logic that doesn't need UIKit/SwiftUI
// In a real implementation, you would move your core models, services, and business logic here

public struct TrainingLoadCalculator {
    public static func calculateCTL(activities: [ActivityData]) -> Double {
        // Placeholder implementation
        return activities.reduce(0) { $0 + $1.tss }
    }
}

public struct ActivityData {
    public let tss: Double
    public let date: Date
    
    public init(tss: Double, date: Date) {
        self.tss = tss
        self.date = date
    }
}
