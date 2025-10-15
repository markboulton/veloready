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
    
    // Track sport ranking selections
    @Published var selectedSports: [SportPreferences.Sport] = []
    @Published var sportRankings: [SportPreferences.Sport: Int] = [:]
    
    enum OnboardingStep: Int, CaseIterable {
        case valueProp = 0
        case whatVeloReady = 1
        case sportRanking = 2
        case healthKit = 3
        case dataSources = 4
        case profile = 5
        case subscription = 6
        
        var title: String {
            switch self {
            case .valueProp: return "Welcome to VeloReady"
            case .whatVeloReady: return "What VeloReady Does"
            case .sportRanking: return "Choose Your Sports"
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
    
    // MARK: - Sport Ranking
    
    /// Update sport ranking when user selects/deselects
    func setSportRanking(_ sport: SportPreferences.Sport, rank: Int?) {
        if let rank = rank {
            sportRankings[sport] = rank
            if !selectedSports.contains(sport) {
                selectedSports.append(sport)
            }
        } else {
            sportRankings.removeValue(forKey: sport)
            selectedSports.removeAll { $0 == sport }
        }
    }
    
    /// Save sport preferences to UserSettings
    func saveSportPreferences() {
        let preferences = SportPreferences(rankings: sportRankings)
        UserSettings.shared.sportPreferences = preferences
        Logger.debug("💾 Sport preferences saved: \(preferences.description)")
    }
    
    /// Get primary sport (rank 1)
    var primarySport: SportPreferences.Sport? {
        sportRankings.first(where: { $0.value == 1 })?.key
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
        Logger.debug("✅ Onboarding completed")
    }
    
    // MARK: - Reset (for debugging)
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = .valueProp
        hasConnectedHealthKit = false
        hasConnectedIntervalsOrStrava = false
        selectedSports = []
        sportRankings = [:]
        
        // Clear saved preferences
        UserDefaults.standard.removeObject(forKey: "preferredUnitSystem")
        UserDefaults.standard.removeObject(forKey: "selectedActivityTypes")
        UserDefaults.standard.removeObject(forKey: "enableNotifications")
        
        Logger.debug("🔄 Onboarding reset - will go through all 7 steps: Value Prop → What VeloReady → Sport Ranking → HealthKit → Data Sources → Profile → Subscription")
    }
}
