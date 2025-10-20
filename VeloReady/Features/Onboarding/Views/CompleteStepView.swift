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
                    .fill(ColorScale.greenAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: Icons.Status.successFill)
                    .font(.system(size: 80))
                    .foregroundColor(ColorScale.greenAccent)
            }
            
            VStack(spacing: 16) {
                Text(OnboardingContent.Complete.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(OnboardingContent.Complete.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                onboardingManager.completeOnboarding()
            }) {
                Text(OnboardingContent.Complete.continueButton)
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
