import SwiftUI

/// Reusable stat row component - label on left, value on right
/// Common pattern throughout the app
struct StatRow: View {
    let label: String
    let value: String
    let valueColor: Color?
    let icon: String?
    
    init(
        label: String,
        value: String,
        valueColor: Color? = nil,
        icon: String? = nil
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.icon = icon
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(width: 20)
            }
            
            Text(label)
                .captionStyle()
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(valueColor ?? .primary)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        StatRow(label: "Duration", value: "45 min")
        StatRow(label: "Distance", value: "12.5 km")
        StatRow(label: "Heart Rate", value: "165 bpm", valueColor: .red, icon: "heart.fill")
        StatRow(label: "Calories", value: "450 kcal", valueColor: ColorPalette.peach)
    }
    .padding()
}
