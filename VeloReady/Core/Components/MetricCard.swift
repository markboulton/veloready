import SwiftUI

/// Reusable metric card showing icon, value, and title
struct MetricCard: View {
    let icon: String
    let value: String
    let title: String
    let color: Color?
    let action: (() -> Void)?
    
    init(
        icon: String,
        value: String,
        title: String,
        color: Color? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.value = value
        self.title = title
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color ?? Color.text.secondary)
                .font(.system(size: TypeScale.lg))
            
            Text(value)
                .font(.system(size: TypeScale.md, weight: .bold))
                .lineLimit(1)
            
            Text(title)
                .font(.system(size: TypeScale.xs))
                .foregroundColor(Color.text.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.cardPadding)
        .background(Color.background.card)
        .cornerRadius(Spacing.cardCornerRadius)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        // Row of metric cards
        HStack(spacing: Spacing.md) {
            MetricCard(
                icon: "heart.fill",
                value: "72",
                title: "Recovery",
                color: Color.recovery.green
            )
            
            MetricCard(
                icon: "moon.fill",
                value: "85",
                title: "Sleep",
                color: Color.sleep.excellent
            )
            
            MetricCard(
                icon: "figure.walk",
                value: "45",
                title: "Load",
                color: Color.strain.moderate
            )
        }
        
        // Single metric card with action
        MetricCard(
            icon: "flame.fill",
            value: "1,234",
            title: "Calories Burned",
            color: .orange,
            action: {
                Logger.debug("Tapped")
            }
        )
        
        // Grid of metric cards
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.md) {
            MetricCard(icon: "heart.fill", value: "65", title: "Resting HR", color: Color.health.heartRate)
            MetricCard(icon: "waveform.path.ecg", value: "45", title: "HRV", color: Color.health.hrv)
            MetricCard(icon: "lungs.fill", value: "16", title: "Resp Rate", color: Color.health.respiratory)
            MetricCard(icon: "figure.run", value: "8,432", title: "Steps", color: ColorPalette.mint)
            MetricCard(icon: "bolt.fill", value: "456", title: "Active Cal", color: ColorPalette.peach)
            MetricCard(icon: "arrow.up.right", value: "42", title: "VO₂ Max", color: ColorPalette.purple)
        }
    }
    .padding(Spacing.cardPadding)
    .background(Color.background.primary)
}
