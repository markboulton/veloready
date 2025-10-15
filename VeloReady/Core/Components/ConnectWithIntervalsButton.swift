import SwiftUI

/// Intervals.icu-branded connection button
struct ConnectWithIntervalsButton: View {
    let action: () -> Void
    let isConnected: Bool
    
    var body: some View {
        Button(action: action) {
            Text(isConnected ? "Disconnect from Intervals.icu" : "Connect with Intervals.icu")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isConnected
                        ? Color.red
                        : Color(red: 0/255, green: 122/255, blue: 255/255) // Intervals blue
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
