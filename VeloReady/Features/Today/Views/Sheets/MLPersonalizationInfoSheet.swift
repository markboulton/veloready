import SwiftUI

/// Information sheet explaining ML Personalization
struct MLPersonalizationInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(MLPersonalizationContent.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.text.primary)
                        
                        Text(MLPersonalizationContent.subtitle)
                            .font(.subheadline)
                            .foregroundColor(Color.text.secondary)
                    }
                    .padding(.top, Spacing.xs)
                    
                    Divider()
                    
                    // Why Personalization Matters
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(MLPersonalizationContent.whatIsItTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.text.primary)
                        
                        Text(MLPersonalizationContent.whatIsItBody)
                            .font(.body)
                            .foregroundColor(Color.text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // How It Works
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(MLPersonalizationContent.howItWorksTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.text.primary)
                        
                        Text(MLPersonalizationContent.howItWorksBody)
                            .font(.body)
                            .foregroundColor(Color.text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // What We're Learning
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(MLPersonalizationContent.whatWeLearnTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.text.primary)
                        
                        Text(MLPersonalizationContent.whatWeLearnBody)
                            .font(.body)
                            .foregroundColor(Color.text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Privacy
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.lg) {
                            Image(systemName: Icons.System.lockShield)
                                .foregroundColor(Color.blue)
                            Text(MLPersonalizationContent.privacyTitle)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.text.primary)
                        }
                        
                        Text(MLPersonalizationContent.privacyBody)
                            .font(.body)
                            .foregroundColor(Color.text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)
                    
                    // What Changes
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(MLPersonalizationContent.whatChangesTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.text.primary)
                        
                        Text(MLPersonalizationContent.whatChangesBody)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.light()
                        dismiss()
                    }) {
                        Image(systemName: Icons.Navigation.close)
                            .foregroundColor(ColorScale.labelSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MLPersonalizationInfoSheet()
}
