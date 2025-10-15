import SwiftUI

/// Screen 6: Profile Setup - Units, name, and avatar
struct ProfileSetupStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedUnit: UnitSystem = .metric
    @State private var userName: String = ""
    @State private var selectedAvatar: String = "person.circle.fill"
    
    private let avatarOptions = [
        "person.circle.fill",
        "figure.outdoor.cycle",
        "figure.strengthtraining.traditional",
        "figure.run",
        "figure.walk",
        "figure.hiking"
    ]
    
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
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: selectedAvatar)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Set Up Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Customize your experience")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Name (Optional)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Name (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Your name", text: $userName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 4)
                    }
                    
                    // Avatar Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Avatar")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                            ForEach(avatarOptions, id: \.self) { avatar in
                                Button(action: {
                                    selectedAvatar = avatar
                                }) {
                                    Image(systemName: avatar)
                                        .font(.title)
                                        .foregroundColor(selectedAvatar == avatar ? .white : .blue)
                                        .frame(width: 60, height: 60)
                                        .background(selectedAvatar == avatar ? Color.blue : Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Unit System
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Units")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            ForEach(UnitSystem.allCases, id: \.self) { unit in
                                Button(action: {
                                    selectedUnit = unit
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: unit == .metric ? "ruler" : "ruler.fill")
                                            .font(.title2)
                                            .foregroundColor(selectedUnit == unit ? .white : .blue)
                                        
                                        Text(unit.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedUnit == unit ? .white : .primary)
                                        
                                        Text(unit.distance)
                                            .font(.caption)
                                            .foregroundColor(selectedUnit == unit ? .white.opacity(0.8) : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        selectedUnit == unit
                                            ? Color.blue
                                            : Color(.systemGray6)
                                    )
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                saveProfile()
                onboardingManager.nextStep()
            }) {
                Text("Continue")
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
        .onAppear {
            // Set initial values from UserSettings
            selectedUnit = userSettings.useMetricUnits ? .metric : .imperial
        }
    }
    
    // MARK: - Helper Functions
    
    private func saveProfile() {
        // Save unit preference
        userSettings.useMetricUnits = (selectedUnit == .metric)
        UserDefaults.standard.set(selectedUnit.rawValue, forKey: "preferredUnitSystem")
        
        // Save name (if provided)
        if !userName.isEmpty {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
        
        // Save avatar
        UserDefaults.standard.set(selectedAvatar, forKey: "userAvatar")
        
        Logger.debug("✅ Profile saved: \(selectedUnit.rawValue), Avatar: \(selectedAvatar)")
    }
}

// MARK: - Preview

#Preview {
    ProfileSetupStepView()
}
