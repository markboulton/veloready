import SwiftUI

/// Section prompting user to enable HealthKit
struct HealthKitEnablementSection: View {
    @Binding var showingHealthKitPermissionsSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: Icons.Health.heartFill)
                    .font(.system(size: 48))
                    .foregroundColor(.primary)
                
                Text(TodayContent.healthKitRequired)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(TodayContent.enableHealthDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Benefits list
            VStack(spacing: 12) {
                HealthKitBenefitRow(
                    icon: "heart.circle.fill",
                    title: TodayContent.HealthKitBenefits.recoveryTitle,
                    description: TodayContent.HealthKitBenefits.recoveryDesc
                )
                
                HealthKitBenefitRow(
                    icon: "moon.circle.fill",
                    title: TodayContent.HealthKitBenefits.sleepTitle,
                    description: TodayContent.HealthKitBenefits.sleepDesc
                )
                
                HealthKitBenefitRow(
                    icon: "figure.walk.circle.fill",
                    title: TodayContent.HealthKitBenefits.trainingLoadTitle,
                    description: TodayContent.HealthKitBenefits.trainingLoadDesc
                )
            }
            
            // Enable button
            Button(action: {
                showingHealthKitPermissionsSheet = true
            }) {
                HStack {
                    Image(systemName: Icons.Health.heartFill)
                    Text(TodayContent.HealthKit.enableButton)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorPalette.blue)
            }
            
            SectionDivider()
        }
    }
}

// MARK: - Preview

struct HealthKitEnablementSection_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitEnablementSection(
            showingHealthKitPermissionsSheet: .constant(false)
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
