import Foundation
import SwiftUI

/// Manages onboarding state and progress
@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var currentStep: OnboardingStep = .welcome
    
    // Track what the user has completed
    @Published var hasConnectedHealthKit: Bool = false
    @Published var hasConnectedIntervalsOrStrava: Bool = false
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case benefits = 1
        case healthKit = 2
        case dataSources = 3
        case preferences = 4
        case subscription = 5
        case complete = 6
        
        var title: String {
            switch self {
            case .welcome: return "Welcome to RideReady"
            case .benefits: return "What RideReady Does"
            case .healthKit: return "Apple Health"
            case .dataSources: return "Connect Your Data"
            case .preferences: return "Your Preferences"
            case .subscription: return "Go Pro"
            case .complete: return "All Set!"
            }
        }
    }
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation {
                currentStep = next
            }
        } else {
            completeOnboarding()
        }
    }
    
    func skipStep() {
        nextStep()
    }
    
    func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
        print("✅ Onboarding completed")
    }
    
    // MARK: - Reset (for debugging)
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = .welcome
        hasConnectedHealthKit = false
        hasConnectedIntervalsOrStrava = false
        
        // Clear saved preferences
        UserDefaults.standard.removeObject(forKey: "preferredUnitSystem")
        UserDefaults.standard.removeObject(forKey: "selectedActivityTypes")
        UserDefaults.standard.removeObject(forKey: "enableNotifications")
        
        print("🔄 Onboarding reset - will go through all 7 steps: Welcome → Benefits → HealthKit → Data Sources → Preferences → Subscription → Complete")
    }
}
