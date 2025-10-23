import SwiftUI

/// Training Phase card using atomic CardContainer wrapper
struct TrainingPhaseCardV2: View {
    let currentPhase: String
    let phaseDescription: String
    let dayInPhase: Int
    let totalDays: Int
    
    private var badge: CardHeader.Badge {
        let progress = Double(dayInPhase) / Double(totalDays)
        
        if progress < 0.33 {
            return .init(text: "EARLY", style: .info)
        } else if progress < 0.67 {
            return .init(text: "MID", style: .warning)
        } else {
            return .init(text: "LATE", style: .success)
        }
    }
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: TrendsContent.Cards.trainingPhase,
                subtitle: currentPhase,
                badge: badge
            ),
            style: .standard
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Progress bar
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        VRText("Day \(dayInPhase)", style: .caption, color: Color.text.secondary)
                        Spacer()
                        VRText("\(totalDays) days", style: .caption, color: Color.text.tertiary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.text.tertiary.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(ColorScale.blueAccent)
                                .frame(width: geometry.size.width * (Double(dayInPhase) / Double(totalDays)), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Description
                VRText(phaseDescription, style: .body, color: Color.text.secondary)
                    .lineLimit(3)
            }
        }
    }
}

#Preview {
    TrainingPhaseCardV2(
        currentPhase: "Base Building",
        phaseDescription: "Focus on aerobic endurance and building sustainable fitness foundation",
        dayInPhase: 18,
        totalDays: 42
    )
    .padding()
}
