import SwiftUI

/// Intervals.icu-branded connection button
struct ConnectWithIntervalsButton: View {
    let action: () -> Void
    let isConnected: Bool
    
    var body: some View {
        Button(action: action) {
            Text(isConnected ? CommonContent.DataSources.intervalsDisconnect : CommonContent.DataSources.intervalsConnect)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.labelPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(
                    isConnected
                        ? ColorPalette.error
                        : Color(red: 0/255, green: 122/255, blue: 255/255) // Intervals blue
                )
                .cornerRadius(Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Compact Intervals.icu badge
struct IntervalsBadge: View {
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: Icons.DataSource.intervalsICU)
                .font(TypeScale.font(size: TypeScale.xs))
                .foregroundColor(ColorPalette.labelPrimary)
            
            Text(CommonContent.DataSources.intervalsName)
                .font(TypeScale.font(size: TypeScale.xs, weight: .semibold))
                .foregroundColor(ColorPalette.labelPrimary)
        }
        .padding(.horizontal, Spacing.sm + 2)
        .padding(.vertical, Spacing.xs + 1)
        .background(Color(red: 0/255, green: 122/255, blue: 255/255))
        .cornerRadius(Spacing.xs)
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
