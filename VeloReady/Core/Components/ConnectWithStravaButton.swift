import SwiftUI

/// Strava-branded "Connect with Strava" button
/// Follows Strava's brand guidelines: https://developers.strava.com/guidelines/
struct ConnectWithStravaButton: View {
    let action: () -> Void
    let isConnected: Bool
    var connectionState: StravaConnectionState = .disconnected
    
    var body: some View {
        Button(action: action) {
            // Text based on state
            Text(buttonText)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.labelPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(backgroundColor)
                .cornerRadius(Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(connectionState.isLoading)
    }
    
    private var buttonText: String {
        switch connectionState {
        case .disconnected:
            return ComponentContent.DataSource.stravaConnect
        case .connecting:
            return ComponentContent.DataSource.stravaConnecting
        case .pending(let status):
            return status
        case .connected:
            return ComponentContent.DataSource.stravaDisconnect
        case .error(let message):
            return ComponentContent.DataSource.errorPrefix + message
        }
    }
    
    private var backgroundColor: Color {
        switch connectionState {
        case .error:
            return ColorPalette.error
        case .connected:
            return ColorPalette.error.opacity(0.8) // Disconnect button
        default:
            // Strava orange: #FC4C02
            return Color(red: 252/255, green: 76/255, blue: 2/255)
        }
    }
}

/// Compact Strava badge
struct StravaBadge: View {
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "figure.outdoor.cycle")
                .font(TypeScale.font(size: TypeScale.xs))
                .foregroundColor(ColorPalette.labelPrimary)
            
            Text(ComponentContent.DataSource.stravaName)
                .font(TypeScale.font(size: TypeScale.xs, weight: .semibold))
                .foregroundColor(ColorPalette.labelPrimary)
        }
        .padding(.horizontal, Spacing.sm + 2)
        .padding(.vertical, Spacing.xs + 1)
        .background(Color(red: 252/255, green: 76/255, blue: 2/255))
        .cornerRadius(Spacing.xs)
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
