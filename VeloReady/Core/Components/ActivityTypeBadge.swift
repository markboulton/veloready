import SwiftUI

/// Badge specifically for activity types with pastel colors
struct ActivityTypeBadge: View {
    let type: String
    let size: BadgeSize
    
    init(_ type: String, size: BadgeSize = .small) {
        self.type = type
        self.size = size
    }
    
    var body: some View {
        Text(displayText)
            .font(.system(size: size.fontSize, weight: .semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(backgroundColor)
            .cornerRadius(size.cornerRadius)
    }
    
    // MARK: - Text Color
    
    private var textColor: Color {
        // Use white text on pastel backgrounds for best contrast
        Color.white
    }
    
    // MARK: - Display Text
    
    private var displayText: String {
        let lowercased = type.lowercased()
        
        // Map specific types to display names
        switch lowercased {
        case "ride", "cycling":
            return "Ride"
        case "virtualride":
            return "Virtual Ride"
        case "run", "running":
            return "Run"
        case "walk", "walking":
            return "Walk"
        case "swim", "swimming":
            return "Swim"
        case "strength", "weighttraining":
            return "Strength"
        case "yoga":
            return "Yoga"
        case "hiit":
            return "HIIT"
        default:
            return type.capitalized
        }
    }
    
    // MARK: - Colors
    
    private var backgroundColor: Color {
        let lowercased = type.lowercased()
        
        switch lowercased {
        case "ride", "cycling", "virtualride":
            return Color.activityType.cycling
        case "run", "running":
            return Color.activityType.running
        case "walk", "walking":
            return Color.activityType.walking
        case "swim", "swimming":
            return Color.activityType.swimming
        case "strength", "weighttraining":
            return Color.activityType.strength
        case "yoga":
            return Color.activityType.yoga
        case "hiit":
            return Color.activityType.hiit
        case "hike", "hiking":
            return Color.activityType.hiking
        default:
            return Color.activityType.other
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ActivityTypeBadge("Ride")
        ActivityTypeBadge("VirtualRide")
        ActivityTypeBadge("Run")
        ActivityTypeBadge("Walk")
        ActivityTypeBadge("Swim")
        ActivityTypeBadge("Strength")
        ActivityTypeBadge("Yoga")
    }
    .padding()
}
