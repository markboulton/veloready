import SwiftUI

/// Header section showing main strain score with ring
struct StrainHeaderSection: View {
    let strainScore: StrainScore
    
    var body: some View {
        VStack(spacing: Spacing.xs / 2) {
            // Main score ring
            ZStack {
                Circle()
                    .stroke(ColorPalette.neutral200, lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                // Convert 0-18 score to 0-100 percentage for ring display
                let ringProgress = strainScore.score / 18.0
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        strainScore.band.colorToken,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: strainScore.score)
                
                VStack(spacing: Spacing.xs / 2) {
                    // Display 0-18 scale with 1 decimal
                    Text(strainScore.formattedScore)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(strainScore.band.colorToken)
                    
                    Text("of 18")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            // Brief description
            Text(strainScore.dailyBrief)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

