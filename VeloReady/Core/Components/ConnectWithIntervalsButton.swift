import SwiftUI

/// Intervals.icu-branded connection button
struct ConnectWithIntervalsButton: View {
    let action: () -> Void
    let isConnected: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Intervals.icu logo (using chart icon as placeholder)
                Image(systemName: isConnected ? "xmark.circle.fill" : "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(isConnected ? "Disconnect from Intervals.icu" : "Connect with Intervals.icu")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isConnected ? [
                        Color.red,
                        Color(red: 0.8, green: 0, blue: 0)
                    ] : [
                        Color(red: 0/255, green: 122/255, blue: 255/255), // Intervals blue
                        Color(red: 0/255, green: 102/255, blue: 204/255)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Compact Intervals.icu badge
struct IntervalsBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption)
                .foregroundColor(.white)
            
            Text("Intervals.icu")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(red: 0/255, green: 122/255, blue: 255/255))
        .cornerRadius(6)
    }
}

// MARK: - Preview

struct ConnectWithIntervalsButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ConnectWithIntervalsButton(action: {}, isConnected: false)
            ConnectWithIntervalsButton(action: {}, isConnected: true)
            IntervalsBadge()
        }
        .padding()
    }
}
