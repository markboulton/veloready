import SwiftUI

/// Main app coordinator that manages navigation and app state
@MainActor
class AppCoordinator: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    
    init() {
        // Initialize app state
        checkAuthenticationStatus()
        checkOnboardingStatus()
    }
    
    private func checkAuthenticationStatus() {
        // TODO: Check if user is authenticated
        isAuthenticated = false
    }
    
    private func checkOnboardingStatus() {
        // TODO: Check if user has completed onboarding
        hasCompletedOnboarding = false
    }
}