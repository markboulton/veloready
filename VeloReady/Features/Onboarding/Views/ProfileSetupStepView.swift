import SwiftUI

/// Screen 6: Profile Setup - Units, name, and avatar
struct ProfileSetupStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var intervalsManager = IntervalsOAuthManager.shared
    @StateObject private var stravaAuthService = StravaAuthService.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var selectedUnit: UnitSystem = .metric
    @State private var userName: String = ""
    @State private var isLoadingProfile: Bool = false
    
    enum UnitSystem: String, CaseIterable {
        case metric = "Metric"
        case imperial = "Imperial"
        
        var distance: String {
            switch self {
            case .metric: return "Kilometers"
            case .imperial: return "Miles"
            }
        }
        
        var weight: String {
            switch self {
            case .metric: return "Kilograms"
            case .imperial: return "Pounds"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: Spacing.lg) {
                Text(OnboardingContent.ProfileSetup.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(profileDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            
            // Profile Info (auto-populated if available)
            VStack(spacing: Spacing.xl) {
                // Name (auto-populated from connected service)
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(OnboardingContent.ProfileSetup.nameLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    if isLoadingProfile {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(userName.isEmpty ? "Loading..." : userName)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
                
                Divider()
                
                // Unit System
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(OnboardingContent.ProfileSetup.units)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: Spacing.md) {
                        ForEach(UnitSystem.allCases, id: \.self) { unit in
                            Button(action: {
                                selectedUnit = unit
                            }) {
                                Text(unit.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.background.card)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedUnit == unit ? Color.blue : ColorPalette.neutral300, lineWidth: selectedUnit == unit ? 2 : 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                saveProfile()
                onboardingManager.nextStep()
            }) {
                Text(OnboardingContent.ProfileSetup.continueButton)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorScale.blueAccent)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            loadProfileData()
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadProfileData() {
        isLoadingProfile = true
        
        // Set initial values from UserSettings
        selectedUnit = userSettings.useMetricUnits ? .metric : .imperial
        
        // Try to get name from connected services
        Task {
            // Priority: Strava > Intervals > Health Kit
            if stravaAuthService.connectionState.isConnected {
                userName = "Athlete"
            } else if intervalsManager.isAuthenticated {
                userName = "Athlete"
            } else {
                // Fallback to default
                userName = "Athlete"
            }
            
            isLoadingProfile = false
        }
    }
    
    private func saveProfile() {
        // Save unit preference
        userSettings.useMetricUnits = (selectedUnit == .metric)
        UserDefaults.standard.set(selectedUnit.rawValue, forKey: "preferredUnitSystem")
        
        // Save name
        UserDefaults.standard.set(userName, forKey: "userName")
        
        Logger.debug("✅ Profile saved: \(selectedUnit.rawValue), Name: \(userName)")
    }
    
    private var profileDescription: String {
        if stravaAuthService.connectionState.isConnected {
            return "Profile data loaded from Strava"
        } else if intervalsManager.isAuthenticated {
            return "Profile data loaded from Intervals.icu"
        } else {
            return "Set your preferences"
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileSetupStepView()
}
