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
    
    @Published var currentStep: OnboardingStep = .valueProp
    
    // Track what the user has completed
    @Published var hasConnectedHealthKit: Bool = false
    @Published var hasConnectedIntervalsOrStrava: Bool = false
    
    // Sport preferences - default to cycling
    // VeloReady is a cycling-specific app
    
    enum OnboardingStep: Int, CaseIterable {
        case valueProp = 0
        case whatVeloReady = 1
        case healthKit = 2
        case dataSources = 3
        case profile = 4
        case subscription = 5
        
        var title: String {
            switch self {
            case .valueProp: return "Welcome to VeloReady"
            case .whatVeloReady: return "What VeloReady Does"
            case .healthKit: return "Apple Health"
            case .dataSources: return "Connect Your Data"
            case .profile: return "Set Up Your Profile"
            case .subscription: return "Unlock Pro Features"
            }
        }
    }
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Sport Preferences
    
    /// Set default cycling preference on onboarding completion
    func setDefaultCyclingPreference() {
        let preferences = SportPreferences(rankings: [.cycling: 1])
        UserSettings.shared.sportPreferences = preferences
        Logger.debug("💾 Default cycling preference saved")
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
        // Set default cycling preference
        setDefaultCyclingPreference()
        
        withAnimation {
            hasCompletedOnboarding = true
        }
        Logger.debug("✅ Onboarding completed (cycling-focused)")
    }
    
    // MARK: - Reset (for debugging)
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = .valueProp
        hasConnectedHealthKit = false
        hasConnectedIntervalsOrStrava = false
        
        // Clear saved preferences
        UserDefaults.standard.removeObject(forKey: "preferredUnitSystem")
        UserDefaults.standard.removeObject(forKey: "selectedActivityTypes")
        UserDefaults.standard.removeObject(forKey: "enableNotifications")
        
        Logger.debug("🔄 Onboarding reset - will go through 6 steps: Value Prop → What VeloReady → HealthKit → Data Sources → Profile → Subscription")
    }
}
