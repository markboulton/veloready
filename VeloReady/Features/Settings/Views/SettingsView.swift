import SwiftUI

/// Main settings view for user preferences
struct SettingsView: View {
    @ObservedObject var userSettings: UserSettings
    @ObservedObject var proConfig: ProFeatureConfig
    @State private var showingSleepSettings = false
    @State private var showingZoneSettings = false
    @State private var showingDisplaySettings = false
    @State private var showingNotificationSettings = false
    
    init(
        userSettings: UserSettings = .shared,
        proConfig: ProFeatureConfig = .shared
    ) {
        self.userSettings = userSettings
        self.proConfig = proConfig
    }
    
    var body: some View {
        List {
            // Profile Section
            ProfileSection()
            
            // Sleep Settings
            SleepSettingsSection(userSettings: userSettings)
            
            // Data Sources
            DataSourcesSection()
            
            // Training Zones
            TrainingZonesSection(proConfig: proConfig)
            
            // Display Settings
            DisplaySettingsSection()
            
            // Notifications
            NotificationSettingsSection()
            
            // iCloud Sync
            iCloudSection()
            
            // Account Section
            AccountSection(showingDeleteDataAlert: $showingDeleteDataAlert)
            
            // About Section
            AboutSection()
            
            #if DEBUG
            // Debug/Testing Section
            DebugSection()
            #endif
        }
        .navigationTitle(SettingsContent.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingSleepSettings) {
            SleepSettingsView()
        }
        .sheet(isPresented: $showingZoneSettings) {
            TrainingZoneSettingsView()
        }
        .sheet(isPresented: $showingDisplaySettings) {
            DisplaySettingsView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .alert("Delete All Data", isPresented: $showingDeleteDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllLocalData()
            }
        } message: {
            Text("This will delete all cached activities, scores, and metrics from this device. This action cannot be undone. Your data on connected services will not be affected.")
        }
    }
    
    private func deleteAllLocalData() {
        // Clear UserDefaults (cached data)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "cached_activities")
        defaults.removeObject(forKey: "cached_wellness")
        defaults.removeObject(forKey: "cached_athlete")
        defaults.removeObject(forKey: "activities_cache_timestamp")
        defaults.removeObject(forKey: "wellness_cache_timestamp")
        defaults.removeObject(forKey: "athlete_cache_timestamp")
        
        // Clear Core Data
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = DailyScores.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                context.delete(object)
            }
            try context.save()
            print("✅ All local data deleted")
        } catch {
            print("❌ Error deleting Core Data: \(error)")
        }
    }
    
    @State private var showingDeleteDataAlert = false
}

// MARK: - Pro Feature Toggle (Debug Only)

#if DEBUG
struct ProFeatureToggle: View {
    @ObservedObject var config = ProFeatureConfig.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable Pro Features (Testing)", isOn: $config.bypassSubscriptionForTesting)
                .onChange(of: config.bypassSubscriptionForTesting) { newValue in
                    if newValue {
                        config.enableProForTesting()
                    } else {
                        config.disableProForTesting()
                    }
                }
            
            if config.bypassSubscriptionForTesting {
                Text("✅ All Pro features unlocked for testing")
                    .font(.caption)
                    .foregroundColor(Color.semantic.success)
            }
            
            Divider()
            
            Toggle("Show Mock Data (Weekly Trends)", isOn: $config.showMockDataForTesting)
            
            if config.showMockDataForTesting {
                Text("📊 Mock data enabled for weekly trend charts")
                    .font(.caption)
                    .foregroundColor(Color.button.primary)
            }
            
            Divider()
            
            HStack {
                Text("Subscription Status:")
                    .font(.subheadline)
                Spacer()
                Text(config.hasProAccess ? "Pro" : "Free")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(config.hasProAccess ? Color.semantic.success : Color.semantic.warning)
            }
            
            if config.isInTrialPeriod {
                HStack {
                    Text("Trial Days Remaining:")
                        .font(.subheadline)
                    Spacer()
                    Text("\(config.trialDaysRemaining)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
#endif

// MARK: - Sleep Settings View

struct SleepSettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sleep Target")
                            .font(.headline)
                        
                        HStack {
                            Text("Hours:")
                                .frame(width: 60, alignment: .leading)
                            
                            Stepper(value: $userSettings.sleepTargetHours, in: 4...12, step: 0.5) {
                                Text("\(userSettings.sleepTargetHours, specifier: "%.1f")")
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                        
                        HStack {
                            Text("Minutes:")
                                .frame(width: 60, alignment: .leading)
                            
                            Stepper(value: $userSettings.sleepTargetMinutes, in: 0...59, step: 15) {
                                Text("\(userSettings.sleepTargetMinutes)")
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                        
                        Text("Total: \(userSettings.formattedSleepTarget)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Sleep Target")
                } footer: {
                    Text("Set your ideal sleep duration. This affects your sleep score calculation.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sleep Score Components")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Performance")
                                    .font(.subheadline)
                                Spacer()
                                Text("40%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Efficiency")
                                    .font(.subheadline)
                                Spacer()
                                Text("15%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Stage Quality")
                                    .font(.subheadline)
                                Spacer()
                                Text("20%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Disturbances")
                                    .font(.subheadline)
                                Spacer()
                                Text("10%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Timing")
                                    .font(.subheadline)
                                Spacer()
                                Text("10%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Latency")
                                    .font(.subheadline)
                                Spacer()
                                Text("5%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Score Calculation")
                } footer: {
                    Text("Your sleep score is calculated using these weighted components from your Apple Health data.")
                }
            }
            .navigationTitle(SettingsContent.Sleep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CommonContent.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Training Zone Settings View

struct TrainingZoneSettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var athleteZoneService = AthleteZoneService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Intervals.icu Integration Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Intervals.icu Zones")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    if athleteZoneService.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Button("Sync Zones") {
                                            Task {
                                                await athleteZoneService.fetchAthleteData()
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                        .disabled(athleteZoneService.lastError != nil)
                                    }
                                }
                                
                                if let error = athleteZoneService.lastError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(Color.text.error)
                                        .padding(.top, 4)
                                }
                            }
                        
                        if let athlete = athleteZoneService.athlete {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Athlete: \(athlete.name ?? "Unknown")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let powerZones = athlete.powerZones {
                                    Text("FTP: \(Int(powerZones.ftp ?? 0)) W")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let hrZones = athlete.heartRateZones {
                                    Text("Max HR: \(Int(hrZones.maxHr ?? 0)) bpm")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let lastFetch = athleteZoneService.lastFetchDate {
                                    Text("Last synced: \(lastFetch, style: .relative)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("Tap 'Sync Zones' to import your zones from Intervals.icu")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Zone Source Selection
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Zone Source")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Zone Source", selection: $userSettings.zoneSource) {
                            Text("Intervals.icu").tag("intervals")
                            Text("Manual").tag("manual")
                            Text("Coggan").tag("coggan")
                        }
                        .pickerStyle(.segmented)
                        
                        Text(zoneSourceDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Zone Configuration")
                }
                
                // Coggan FTP/Max HR inputs (show when Coggan selected)
                if userSettings.zoneSource == "coggan" {
                    Section {
                        VStack(spacing: 12) {
                            HStack {
                                Text("FTP")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.freeUserFTP, in: 100...500, step: 10) {
                                    Text("\(userSettings.freeUserFTP) W")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Max HR")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.freeUserMaxHR, in: 100...250, step: 5) {
                                    Text("\(userSettings.freeUserMaxHR) bpm")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                        }
                    } header: {
                        Text("Coggan Zone Parameters")
                    } footer: {
                        Text("Zones will be calculated using standard Coggan percentages from these values.")
                    }
                }
                
                // Current Zone Boundaries Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Zone Boundaries")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Heart Rate Zones:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(1...5, id: \.self) { zone in
                                HStack {
                                    Text("Zone \(zone):")
                                        .font(.caption)
                                    Spacer()
                                    Text("≤ \(athleteZoneService.getHeartRateZoneBoundaries()[zone-1]) bpm")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Power Zones:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(1...5, id: \.self) { zone in
                                HStack {
                                    Text("Zone \(zone):")
                                        .font(.caption)
                                    Spacer()
                                    Text("≤ \(athleteZoneService.getPowerZoneBoundaries()[zone-1]) W")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Heart Rate Zones")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Zone 1 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.hrZone1Max, in: 100...250, step: 5) {
                                    Text("\(userSettings.hrZone1Max) bpm")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Zone 2 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.hrZone2Max, in: 100...250, step: 5) {
                                    Text("\(userSettings.hrZone2Max) bpm")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Zone 3 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.hrZone3Max, in: 100...250, step: 5) {
                                    Text("\(userSettings.hrZone3Max) bpm")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Zone 4 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.hrZone4Max, in: 100...250, step: 5) {
                                    Text("\(userSettings.hrZone4Max) bpm")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Zone 5 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.hrZone5Max, in: 100...250, step: 5) {
                                    Text("\(userSettings.hrZone5Max) bpm")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Heart Rate Zones")
                } footer: {
                    Text("Set your heart rate zone boundaries. These can be imported from Intervals.icu.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Power Zones")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Zone 1 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.powerZone1Max, in: 100...500, step: 10) {
                                    Text("\(userSettings.powerZone1Max) W")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Zone 2 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.powerZone2Max, in: 100...500, step: 10) {
                                    Text("\(userSettings.powerZone2Max) W")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Zone 3 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.powerZone3Max, in: 100...500, step: 10) {
                                    Text("\(userSettings.powerZone3Max) W")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Zone 4 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.powerZone4Max, in: 100...500, step: 10) {
                                    Text("\(userSettings.powerZone4Max) W")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Zone 5 Max:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Stepper(value: $userSettings.powerZone5Max, in: 100...500, step: 10) {
                                    Text("\(userSettings.powerZone5Max) W")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Power Zones")
                } footer: {
                    Text("Set your power zone boundaries. These can be imported from Intervals.icu.")
                }
            }
            .navigationTitle(SettingsContent.TrainingZones.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CommonContent.done) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var zoneSourceDescription: String {
        switch userSettings.zoneSource {
        case "intervals":
            return "Sync zones from Intervals.icu. Tap 'Sync Zones' above to import."
        case "manual":
            return "Edit zone boundaries manually below."
        case "coggan":
            return "Use standard Coggan zones. Set your FTP and Max HR below."
        default:
            return ""
        }
    }
}

// MARK: - Display Settings View

struct DisplaySettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Show Sleep Score", isOn: $userSettings.showSleepScore)
                    Toggle("Show Recovery Score", isOn: $userSettings.showRecoveryScore)
                    Toggle("Show Health Data", isOn: $userSettings.showHealthData)
                } header: {
                    Text("Visibility")
                } footer: {
                    Text("Choose which metrics to display on the main screen.")
                }
                
                Section {
                    Toggle("Metric Units", isOn: $userSettings.useMetricUnits)
                    Toggle("24-Hour Time", isOn: $userSettings.use24HourTime)
                } header: {
                    Text("Units & Format")
                } footer: {
                    Text("Configure how measurements and time are displayed.")
                }
                
                Section {
                    Toggle("Use BMR as Calorie Goal", isOn: $userSettings.useBMRAsGoal)
                    
                    if !userSettings.useBMRAsGoal {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Daily Calorie Goal")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Text("Calories:")
                                    .frame(width: 80, alignment: .leading)
                                
                                Stepper(value: $userSettings.calorieGoal, in: 1000...5000, step: 50) {
                                    Text("\(Int(userSettings.calorieGoal))")
                                        .frame(width: 60, alignment: .trailing)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Calorie Goals")
                } footer: {
                    Text("Set your daily calorie goal. Use BMR (Basal Metabolic Rate) or set a custom target.")
                }
            }
            .navigationTitle(SettingsContent.Display.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CommonContent.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Sleep Reminders", isOn: $userSettings.sleepReminders)
                    
                    if userSettings.sleepReminders {
                        DatePicker("Reminder Time", selection: $userSettings.sleepReminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Sleep Reminders")
                } footer: {
                    Text("Get reminded when it's time to wind down for bed.")
                }
                
                Section {
                    Toggle("Recovery Alerts", isOn: $userSettings.recoveryAlerts)
                } header: {
                    Text("Recovery Alerts")
                } footer: {
                    Text("Get notified when your recovery score indicates you should rest.")
                }
            }
            .navigationTitle(SettingsContent.Notifications.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CommonContent.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
