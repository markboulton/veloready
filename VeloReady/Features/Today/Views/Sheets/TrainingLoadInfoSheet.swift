import SwiftUI

/// Information sheet explaining Training Load for strength workouts
struct TrainingLoadInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(StrengthLoadContent.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.text.primary)
                        
                        Text(StrengthLoadContent.subtitle)
                            .font(.subheadline)
                            .foregroundColor(Color.text.secondary)
                    }
                    .padding(.top, 8)
                    
                    Divider()
                    
                    // What Is It
                    VStack(alignment: .leading, spacing: 12) {
                        Text(StrengthLoadContent.whatIsItTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.text.primary)
                        
                        Text(StrengthLoadContent.whatIsItBody)
                            .font(.body)
                            .foregroundColor(Color.text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // How It Works
                    VStack(alignment: .leading, spacing: 12) {
                        Text(StrengthLoadContent.howItWorksTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.text.primary)
                        
                        Text(StrengthLoadContent.howItWorksBody)
                            .font(.body)
                            .foregroundColor(Color.text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Intensity Levels
                    VStack(alignment: .leading, spacing: 16) {
                        Text(StrengthLoadContent.intensityLevelsTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.text.primary)
                        
                        VStack(spacing: 12) {
                            IntensityLevelRow(
                                label: StrengthLoadContent.lightLabel,
                                description: StrengthLoadContent.lightDescription
                            )
                            
                            IntensityLevelRow(
                                label: StrengthLoadContent.moderateLabel,
                                description: StrengthLoadContent.moderateDescription
                            )
                            
                            IntensityLevelRow(
                                label: StrengthLoadContent.hardLabel,
                                description: StrengthLoadContent.hardDescription
                            )
                            
                            IntensityLevelRow(
                                label: StrengthLoadContent.veryHardLabel,
                                description: StrengthLoadContent.veryHardDescription
                            )
                        }
                    }
                    
                    // Why It Matters
                    VStack(alignment: .leading, spacing: 12) {
                        Text(StrengthLoadContent.whyItMattersTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.text.primary)
                        
                        Text(StrengthLoadContent.whyItMattersBody)
                            .font(.body)
                            .foregroundColor(Color.text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(24)
            }
            .background(Color.background.primary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(StrengthLoadContent.closeButton) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Intensity Level Row

private struct IntensityLevelRow: View {
    let label: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.text.primary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(Color.text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(ColorScale.gray100)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    TrainingLoadInfoSheet()
}
