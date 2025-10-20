import SwiftUI

/// View for overriding the X-User header for testing
struct RideSummaryUserOverrideView: View {
    @ObservedObject private var rideSummaryService = RideSummaryService.shared
    @State private var overrideUserId: String = ""
    @State private var useOverride = false
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss
    
    private let overrideKey = "ride_summary_user_override"
    private let overrideEnabledKey = "ride_summary_user_override_enabled"
    
    var body: some View {
        Form {
            Section {
                Toggle("Override User ID", isOn: $useOverride)
                    .onChange(of: useOverride) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: overrideEnabledKey)
                        if !newValue {
                            // Clear override when disabled
                            UserDefaults.standard.removeObject(forKey: overrideKey)
                        }
                    }
                
                if useOverride {
                    TextField("User ID", text: $overrideUserId)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                    
                    Button(action: {
                        UserDefaults.standard.set(overrideUserId, forKey: overrideKey)
                        saved = true
                        
                        // Reset after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            saved = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Save Override")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(overrideUserId.isEmpty)
                    
                    if saved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.semantic.success)
                            Text("Override saved")
                                .font(.caption)
                                .foregroundColor(Color.semantic.success)
                        }
                    }
                }
            } header: {
                Label("User ID Override", systemImage: "person.crop.circle")
            } footer: {
                Text("Override the X-User header for testing different user accounts. This affects both AI Brief and Ride Summary.")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current User ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(getCurrentUserId())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Actual User ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(rideSummaryService.userId)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            } header: {
                Label("Current Values", systemImage: "info.circle")
            } footer: {
                Text("'Current User ID' is what will be sent in requests. 'Actual User ID' is the device's anonymous ID.")
            }
            
            Section {
                Button(action: {
                    useOverride = false
                    overrideUserId = ""
                    UserDefaults.standard.removeObject(forKey: overrideKey)
                    UserDefaults.standard.set(false, forKey: overrideEnabledKey)
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Default")
                    }
                }
                .buttonStyle(.bordered)
                .tint(Color.button.danger)
            }
        }
        .navigationTitle(SettingsContent.RideSummary.overrideUserNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            useOverride = UserDefaults.standard.bool(forKey: overrideEnabledKey)
            if let override = UserDefaults.standard.string(forKey: overrideKey) {
                overrideUserId = override
            }
        }
    }
    
    private func getCurrentUserId() -> String {
        if let override = UserDefaults.standard.string(forKey: overrideKey),
           UserDefaults.standard.bool(forKey: overrideEnabledKey) {
            return override
        }
        return rideSummaryService.userId
    }
}

#Preview {
    NavigationView {
        RideSummaryUserOverrideView()
    }
}
