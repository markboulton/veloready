import SwiftUI

/// Header section showing main sleep score with ring
struct SleepHeaderSection: View {
    let sleepScore: SleepScore
    
    var body: some View {
        VStack(spacing: 16) {
            // Main score ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: Double(sleepScore.score) / 100.0)
                    .stroke(
                        sleepScore.band.colorToken,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: sleepScore.score)
                
                VStack(spacing: 4) {
                    Text("\(sleepScore.score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(sleepScore.band.colorToken)
                    
                    Text(sleepScore.band.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(sleepScore.dailyBrief)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
