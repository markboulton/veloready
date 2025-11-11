import SwiftUI

/// Card showing recovery factors with progress bars
/// Displays the component parts that make up the recovery score
struct RecoveryFactorsCard: View {
    @ObservedObject private var stressService = StressAnalysisService.shared
    
    var body: some View {
        StandardCard(
            title: StressContent.RecoveryFactors.title,
            subtitle: StressContent.RecoveryFactors.subtitle
        ) {
            VStack(spacing: Spacing.lg) {
                ForEach(stressService.getRecoveryFactors()) { factor in
                    factorRow(factor)
                }
            }
        }
    }
    
    private func factorRow(_ factor: RecoveryFactor) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Heading and status on same line
            HStack(alignment: .center) {
                // Factor label
                Text(factor.type.label)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
                
                Spacer()
                
                // Status label with color
                Text(factor.status.label(for: factor.type))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(factor.status.color)
            }
            
            // Progress bar with vertical padding
            progressBar(value: factor.value, color: factor.status.color)
                .padding(.vertical, Spacing.xs / 2)  // ADD PADDING HERE: Spacing.xs / 2 above and below
        }
    }
    
    private func progressBar(value: Int, color: Color) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(ColorPalette.backgroundTertiary)
                    .frame(height: 2)
                
                // Progress (white indicator)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * CGFloat(value) / 100.0, height: 2)
            }
        }
        .frame(height: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        RecoveryFactorsCard()
            .padding()
        
        // Show what the card looks like in context
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Mock recovery ring
                ZStack {
                    Circle()
                        .stroke(ColorScale.greenAccent.opacity(0.3), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    VStack {
                        Text("72")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.text.primary)
                        Text("Good")
                            .font(.caption)
                            .foregroundColor(.text.secondary)
                    }
                }
                .padding(.vertical, Spacing.xl)
                
                // The factors card
                RecoveryFactorsCard()
            }
            .padding(.horizontal, Spacing.xl)
        }
        .background(Color.background.app)
    }
}

