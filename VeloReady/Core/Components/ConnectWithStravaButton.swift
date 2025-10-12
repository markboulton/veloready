import SwiftUI

/// Strava-branded "Connect with Strava" button
/// Follows Strava's brand guidelines: https://developers.strava.com/guidelines/
struct ConnectWithStravaButton: View {
    let action: () -> Void
    let isConnected: Bool
    var connectionState: StravaConnectionState = .disconnected
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon based on state
                Group {
                    switch connectionState {
                    case .connecting, .pending:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    case .connected:
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    case .error:
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                    case .disconnected:
                        Image(systemName: "figure.outdoor.cycle")
                            .font(.title3)
                    }
                }
                .foregroundColor(.white)
                
                // Text based on state
                Text(buttonText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .cornerRadius(4) // Strava uses small corner radius
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(connectionState.isLoading)
    }
    
    private var buttonText: String {
        switch connectionState {
        case .disconnected:
            return "Connect with Strava"
        case .connecting:
            return "Connecting..."
        case .pending(let status):
            return status
        case .connected:
            return "Disconnect from Strava"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var backgroundColor: Color {
        switch connectionState {
        case .error:
            return Color.red
        case .connected:
            return Color.red.opacity(0.8) // Disconnect button
        default:
            // Strava orange: #FC4C02
            return Color(red: 252/255, green: 76/255, blue: 2/255)
        }
    }
}

/// Compact Strava badge
struct StravaBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.outdoor.cycle")
                .font(.caption)
                .foregroundColor(.white)
            
            Text("Strava")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(red: 252/255, green: 76/255, blue: 2/255))
        .cornerRadius(4)
    }
}

// MARK: - Preview

struct ConnectWithStravaButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ConnectWithStravaButton(action: {}, isConnected: false)
            ConnectWithStravaButton(action: {}, isConnected: true)
            StravaBadge()
        }
        .padding()
    }
}
