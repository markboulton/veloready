import SwiftUI

/// Live activity panel showing calories burned
struct LiveCaloriesPanel: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    
    init(liveActivityService: LiveActivityService) {
        self.liveActivityService = liveActivityService
    }
    
    var body: some View {
        Card {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(ColorPalette.peach)
                        .font(.title2)
                    
                    Text(TodayContent.calories)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if liveActivityService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(liveActivityService.dailyCalories))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(TodayContent.kcal)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    Spacer()
                }
                
                if let lastUpdated = liveActivityService.lastUpdated {
                    Text("\(TodayContent.updated) \(formatLastUpdated(lastUpdated))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// Live activity panel showing step count
struct LiveStepsPanel: View {
    @ObservedObject private var liveActivityService: LiveActivityService
    
    init(liveActivityService: LiveActivityService) {
        self.liveActivityService = liveActivityService
    }
    
    var body: some View {
        Card {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(ColorPalette.mint)
                        .font(.title2)
                    
                    Text(TodayContent.steps)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if liveActivityService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(formatSteps(liveActivityService.dailySteps))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(TodayContent.stepsUnit)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    Spacer()
                }
                
                if let lastUpdated = liveActivityService.lastUpdated {
                    Text("\(TodayContent.updated) \(formatLastUpdated(lastUpdated))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fK", Double(steps) / 1000.0)
        } else {
            return "\(steps)"
        }
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            LiveCaloriesPanel(liveActivityService: LiveActivityService(oauthManager: IntervalsOAuthManager()))
                .frame(maxWidth: .infinity)
            
            LiveStepsPanel(liveActivityService: LiveActivityService(oauthManager: IntervalsOAuthManager()))
                .frame(maxWidth: .infinity)
        }
    }
    .padding()
}
