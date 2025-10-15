import SwiftUI

/// Main onboarding flow container
struct OnboardingFlowView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Step content
            Group {
                switch onboardingManager.currentStep {
                case .valueProp:
                    ValuePropStepView()
                case .whatVeloReady:
                    WhatVeloReadyStepView()
                case .healthKit:
                    HealthKitStepView()
                case .dataSources:
                    DataSourcesStepView()
                case .profile:
                    ProfileSetupStepView()
                case .subscription:
                    SubscriptionStepView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }
}

// MARK: - Preview

struct OnboardingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlowView()
    }
}
