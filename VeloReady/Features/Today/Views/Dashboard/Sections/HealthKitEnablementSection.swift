import SwiftUI

/// Section prompting user to enable HealthKit
struct HealthKitEnablementSection: View {
    @Binding var showingHealthKitPermissionsSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ColorScale.pinkAccent)
                
                Text(TodayContent.healthKitRequired)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Connect your Apple Health data to see personalized recovery scores, sleep analysis, and training insights.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Benefits list
            VStack(spacing: 12) {
                HealthKitBenefitRow(
                    icon: "heart.circle.fill",
                    title: "Recovery Score",
                    description: "Track your readiness based on HRV, sleep, and training"
                )
                
                HealthKitBenefitRow(
                    icon: "moon.circle.fill",
                    title: "Sleep Analysis",
                    description: "Understand your sleep quality and patterns"
                )
                
                HealthKitBenefitRow(
                    icon: "figure.walk.circle.fill",
                    title: "Training Load",
                    description: "Monitor your training stress and recovery balance"
                )
            }
            
            // Enable button
            Button(action: {
                showingHealthKitPermissionsSheet = true
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Enable Health Data")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorScale.pinkAccent)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
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
