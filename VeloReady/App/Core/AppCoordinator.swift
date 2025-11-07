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
        isAuthenticated = false
    }
    
    private func checkOnboardingStatus() {
        hasCompletedOnboarding = false
    }
}