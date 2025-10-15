import SwiftUI

/// Step 5: User preferences and profile setup
struct PreferencesStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedUnit: UnitSystem = .metric
    @State private var selectedActivities: Set<ActivityType> = [.cycling, .running]
    @State private var enableNotifications: Bool = true
    
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
    
    enum ActivityType: String, CaseIterable, Identifiable {
        case cycling = "Cycling"
        case running = "Running"
        case swimming = "Swimming"
        case walking = "Walking"
        case hiking = "Hiking"
        case other = "Other"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .cycling: return "figure.outdoor.cycle"
            case .running: return "figure.run"
            case .swimming: return "figure.pool.swim"
            case .walking: return "figure.walk"
            case .hiking: return "figure.hiking"
            case .other: return "figure.mixed.cardio"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
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
                    // Unit System
                    unitSystemSection
                    
                    // Activity Types
                    activityTypesSection
                    
                    // Notifications
                    notificationsSection
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                savePreferences()
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
    }
    
    // MARK: - Sections
    
    private var unitSystemSection: some View {
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
    
    private var activityTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activities to Track")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Select which activities you want to see in your feed")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ActivityType.allCases) { activity in
                    Button(action: {
                        if selectedActivities.contains(activity) {
                            selectedActivities.remove(activity)
                        } else {
                            selectedActivities.insert(activity)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: activity.icon)
                                .font(.body)
                                .foregroundColor(selectedActivities.contains(activity) ? .white : .blue)
                            
                            Text(activity.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedActivities.contains(activity) ? .white : .primary)
                            
                            Spacer()
                            
                            if selectedActivities.contains(activity) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            selectedActivities.contains(activity)
                                ? Color.blue
                                : Color(.systemGray6)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle(isOn: $enableNotifications) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery Reminders")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Get notified about your daily recovery score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Helper Functions
    
    private func savePreferences() {
        // Save unit preference
        UserDefaults.standard.set(selectedUnit.rawValue, forKey: "preferredUnitSystem")
        
        // Save activity filters
        let activityNames = selectedActivities.map { $0.rawValue }
        UserDefaults.standard.set(activityNames, forKey: "selectedActivityTypes")
        
        // Save notification preference
        UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications")
        
        Logger.debug("✅ Preferences saved: \(selectedUnit.rawValue), \(activityNames.joined(separator: ", "))")
    }
}

// MARK: - Preview

struct PreferencesStepView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesStepView()
    }
}
