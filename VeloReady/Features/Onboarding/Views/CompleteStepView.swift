import SwiftUI

/// Step 5: Onboarding complete (not really used as we go straight to Today)
struct CompleteStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                Text("All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("You're ready to start tracking your rides")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                onboardingManager.completeOnboarding()
            }) {
                Text("Start Using RideReady")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview

struct CompleteStepView_Previews: PreviewProvider {
    static var previews: some View {
        CompleteStepView()
    }
}
