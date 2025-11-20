import SwiftUI

/// Main settings view for user preferences
struct SettingsView: View {
    @ObservedObject private var viewState = SettingsViewState.shared
    @StateObject private var proConfig = ProFeatureConfig.shared
    @State private var showingDeleteDataAlert = false

    var body: some View {
        NavigationView {
            List {
                // Profile Section
                ProfileSection()
                
                // Goals (Steps & Calories)
                GoalsSettingsSection()

                // Sleep Settings
                SleepSettingsSection()

                // Data Sources
                DataSourcesSection()
                
                // ML Personalization
                MLPersonalizationSection()
                
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
                
                // Help & Feedback Section (always visible)
                FeedbackSection()
                
                // Debug/Testing Section (developers only - controlled by DebugFlags)
                DebugSection()
            }
            .navigationTitle(SettingsContent.title)
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Load settings when view appears
                await viewState.load()
            }
        }
        .alert(SettingsContent.Account.deleteDataTitle, isPresented: $showingDeleteDataAlert) {
            Button(CommonContent.cancel, role: .cancel) { }
            Button(SettingsContent.Account.delete, role: .destructive) {
                deleteAllLocalData()
            }
        } message: {
            Text(SettingsContent.Account.deleteDataMessage)
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
            Logger.debug("✅ All local data deleted")
        } catch {
            Logger.error("Error deleting Core Data: \(error)")
        }
    }
}

// MARK: - Pro Feature Toggle (Debug Only)

#if DEBUG
struct ProFeatureToggle: View {
    @ObservedObject var config = ProFeatureConfig.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Toggle(SettingsContent.DebugSettings.enableProTesting, isOn: $config.bypassSubscriptionForTesting)
                .onChange(of: config.bypassSubscriptionForTesting) { _, newValue in
                    if newValue {
                        config.enableProForTesting()
                    } else {
                        config.disableProForTesting()
                    }
                }
            
            if config.bypassSubscriptionForTesting {
                Text(SettingsContent.DebugSettings.proFeaturesUnlocked)
                    .font(.caption)
                    .foregroundColor(Color.semantic.success)
            }
            
            Divider()
            
            Toggle(SettingsContent.DebugSettings.showMockData, isOn: $config.showMockDataForTesting)
            
            if config.showMockDataForTesting {
                Text(SettingsContent.DebugSettings.mockDataEnabled)
                    .font(.caption)
                    .foregroundColor(Color.button.primary)
            }
            
            Divider()
            
            HStack {
                Text(SettingsContent.DebugSettings.subscriptionStatus)
                    .font(.subheadline)
                Spacer()
                Text(config.hasProAccess ? SettingsContent.DebugSettings.pro : SettingsContent.DebugSettings.free)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(config.hasProAccess ? Color.semantic.success : Color.semantic.warning)
            }
            
            if config.isInTrialPeriod {
                HStack {
                    Text(SettingsContent.DebugSettings.trialDaysRemaining)
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
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text(SettingsContent.Sleep.targetTitle)
                            .font(.headline)
                        
                        HStack {
                            Text(SettingsContent.Sleep.hoursLabel)
                                .frame(width: 60, alignment: .leading)
                            
                            Stepper(value: $userSettings.sleepTargetHours, in: 4...12, step: 0.5) {
                                Text("\(userSettings.sleepTargetHours, specifier: "%.1f")")
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                        
                        HStack {
                            Text(SettingsContent.Sleep.minutesLabel)
                                .frame(width: 60, alignment: .leading)
                            
                            Stepper(value: $userSettings.sleepTargetMinutes, in: 0...59, step: 15) {
                                Text("\(userSettings.sleepTargetMinutes)")
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                        
                        Text("\(SettingsContent.Sleep.totalLabel) \(userSettings.formattedSleepTarget)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(SettingsContent.Sleep.targetTitle)
                } footer: {
                    Text(SettingsContent.Sleep.targetDescription)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(SettingsContent.Sleep.componentsTitle)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text(SettingsContent.SleepComponents.performance)
                                    .font(.subheadline)
                                Spacer()
                                Text(SettingsContent.SleepComponents.performancePercent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(SettingsContent.SleepComponents.efficiency)
                                    .font(.subheadline)
                                Spacer()
                                Text(SettingsContent.SleepComponents.efficiencyPercent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(SettingsContent.SleepComponents.stageQuality)
                                    .font(.subheadline)
                                Spacer()
                                Text(SettingsContent.SleepComponents.stageQualityPercent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(SettingsContent.SleepComponents.disturbances)
                                    .font(.subheadline)
                                Spacer()
                                Text(SettingsContent.SleepComponents.disturbancesPercent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(SettingsContent.SleepComponents.timing)
                                    .font(.subheadline)
                                Spacer()
                                Text(SettingsContent.SleepComponents.timingPercent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(SettingsContent.SleepComponents.latency)
                                    .font(.subheadline)
                                Spacer()
                                Text(SettingsContent.SleepComponents.latencyPercent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(SettingsContent.SleepComponents.scoreCalculation)
                } footer: {
                    Text(SettingsContent.Sleep.componentsDescription)
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
    @ObservedObject private var viewState = SettingsViewState.shared
    @StateObject private var athleteZoneService = AthleteZoneService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Intervals.icu Integration Section
                Section {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    Text(SettingsContent.TrainingZones.intervalsSync)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    if athleteZoneService.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Button(SettingsContent.TrainingZones.syncZones) {
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
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("\(SettingsContent.AthleteZones.athlete) \(athlete.name ?? SettingsContent.AthleteZones.unknownAthlete)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let powerZones = athlete.powerZones {
                                    Text("\(SettingsContent.TrainingZones.ftpLabel) \(Int(powerZones.ftp ?? 0)) \(CommonContent.Units.watts))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let hrZones = athlete.heartRateZones {
                                    Text("\(SettingsContent.TrainingZones.maxHRLabel) \(Int(hrZones.maxHr ?? 0)) \(CommonContent.Units.bpm))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let lastFetch = athleteZoneService.lastFetchDate {
                                    Text("\(SettingsContent.TrainingZones.lastSyncLabel) \(lastFetch, style: .relative)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text(SettingsContent.TrainingZones.syncDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Zone Source Selection
                Section {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(SettingsContent.TrainingZones.zoneSource)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker(SettingsContent.TrainingZones.zoneSourcePicker, selection: Binding(
                            get: { viewState.zoneSettings.source },
                            set: { newSource in
                                Task {
                                    let updated = ZoneSettings(
                                        source: newSource,
                                        hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                        hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                        hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                        hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                        hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                        powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                        powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                        powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                        powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                        powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                        freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                        freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                    )
                                    await viewState.saveZoneSettings(updated)
                                }
                            }
                        )) {
                            Text(SettingsContent.TrainingZones.intervals).tag("intervals")
                            Text(SettingsContent.TrainingZones.manual).tag("manual")
                            Text(SettingsContent.TrainingZones.coggan).tag("coggan")
                        }
                        .pickerStyle(.segmented)

                        Text(zoneSourceDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(SettingsContent.TrainingZones.zoneConfiguration)
                }

                // Coggan FTP/Max HR inputs (show when Coggan selected)
                if viewState.zoneSettings.source == "coggan" {
                    Section {
                        VStack(spacing: Spacing.md) {
                            HStack {
                                Text(SettingsContent.AthleteZones.ftp)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.freeUserFTP },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: newValue,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...500, step: 10) {
                                    Text("\(viewState.zoneSettings.freeUserFTP) \(CommonContent.Units.watts)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text(SettingsContent.AthleteZones.maxHR)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.freeUserMaxHR },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: newValue
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...250, step: 5) {
                                    Text("\(viewState.zoneSettings.freeUserMaxHR) \(CommonContent.Units.bpm)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                        }
                    } header: {
                        Text(SettingsContent.TrainingZones.cogganParameters)
                    } footer: {
                        Text(SettingsContent.TrainingZones.cogganDescription)
                    }
                }
                
                // Current Zone Boundaries Section
                Section {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(SettingsContent.TrainingZones.currentBoundaries)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(SettingsContent.TrainingZones.heartRateZonesLabel)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(1...5, id: \.self) { zone in
                                HStack {
                                    Text("\(SettingsContent.TrainingZones.zone) \(zone):")
                                        .font(.caption)
                                    Spacer()
                                    Text("≤ \(viewState.zoneSettings.hrZones[zone-1]) \(CommonContent.Units.bpm)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(SettingsContent.TrainingZones.powerZonesLabel)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(1...5, id: \.self) { zone in
                                HStack {
                                    Text("\(SettingsContent.TrainingZones.zone) \(zone):")
                                        .font(.caption)
                                    Spacer()
                                    Text("≤ \(viewState.zoneSettings.powerZones[zone-1]) \(CommonContent.Units.watts)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text(SettingsContent.TrainingZones.heartRateZonesTitle)
                            .font(.headline)
                        
                        VStack(spacing: Spacing.md) {
                            HStack {
                                Text(SettingsContent.TrainingZones.zone1Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.hrZone1Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: newValue,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...250, step: 5) {
                                    Text("\(viewState.zoneSettings.hrZone1Max) \(CommonContent.Units.bpm)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text(SettingsContent.TrainingZones.zone2Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.hrZone2Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: newValue,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...250, step: 5) {
                                    Text("\(viewState.zoneSettings.hrZone2Max) \(CommonContent.Units.bpm)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text(SettingsContent.TrainingZones.zone3Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.hrZone3Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: newValue,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...250, step: 5) {
                                    Text("\(viewState.zoneSettings.hrZone3Max) \(CommonContent.Units.bpm)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text(SettingsContent.TrainingZones.zone4Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.hrZone4Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: newValue,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...250, step: 5) {
                                    Text("\(viewState.zoneSettings.hrZone4Max) \(CommonContent.Units.bpm)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text(SettingsContent.TrainingZones.zone5Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.hrZone5Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: newValue,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...250, step: 5) {
                                    Text("\(viewState.zoneSettings.hrZone5Max) \(CommonContent.Units.bpm)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(SettingsContent.TrainingZones.heartRateZonesTitle)
                } footer: {
                    Text(SettingsContent.TrainingZones.heartRateZonesDescription)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text(SettingsContent.TrainingZones.powerZonesTitle)
                            .font(.headline)
                        
                        VStack(spacing: Spacing.md) {
                            HStack {
                                Text(SettingsContent.TrainingZones.zone1Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.powerZone1Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: newValue,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...500, step: 10) {
                                    Text("\(viewState.zoneSettings.powerZone1Max) \(CommonContent.Units.watts)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text(SettingsContent.TrainingZones.zone2Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.powerZone2Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: newValue,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...500, step: 10) {
                                    Text("\(viewState.zoneSettings.powerZone2Max) \(CommonContent.Units.watts)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text(SettingsContent.TrainingZones.zone3Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.powerZone3Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: newValue,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...500, step: 10) {
                                    Text("\(viewState.zoneSettings.powerZone3Max) \(CommonContent.Units.watts)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text(SettingsContent.TrainingZones.zone4Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.powerZone4Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: newValue,
                                                powerZone5Max: viewState.zoneSettings.powerZone5Max,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...500, step: 10) {
                                    Text("\(viewState.zoneSettings.powerZone4Max) \(CommonContent.Units.watts)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text(SettingsContent.TrainingZones.zone5Max)
                                    .frame(width: 100, alignment: .leading)

                                Stepper(value: Binding(
                                    get: { viewState.zoneSettings.powerZone5Max },
                                    set: { newValue in
                                        Task {
                                            let updated = ZoneSettings(
                                                source: viewState.zoneSettings.source,
                                                hrZone1Max: viewState.zoneSettings.hrZone1Max,
                                                hrZone2Max: viewState.zoneSettings.hrZone2Max,
                                                hrZone3Max: viewState.zoneSettings.hrZone3Max,
                                                hrZone4Max: viewState.zoneSettings.hrZone4Max,
                                                hrZone5Max: viewState.zoneSettings.hrZone5Max,
                                                powerZone1Max: viewState.zoneSettings.powerZone1Max,
                                                powerZone2Max: viewState.zoneSettings.powerZone2Max,
                                                powerZone3Max: viewState.zoneSettings.powerZone3Max,
                                                powerZone4Max: viewState.zoneSettings.powerZone4Max,
                                                powerZone5Max: newValue,
                                                freeUserFTP: viewState.zoneSettings.freeUserFTP,
                                                freeUserMaxHR: viewState.zoneSettings.freeUserMaxHR
                                            )
                                            await viewState.saveZoneSettings(updated)
                                        }
                                    }
                                ), in: 100...500, step: 10) {
                                    Text("\(viewState.zoneSettings.powerZone5Max) \(CommonContent.Units.watts)")
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(SettingsContent.TrainingZones.powerZonesTitle)
                } footer: {
                    Text(SettingsContent.TrainingZones.powerZonesDescription)
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
        switch viewState.zoneSettings.source {
        case "intervals":
            return SettingsContent.TrainingZones.intervalsDescription
        case "manual":
            return SettingsContent.TrainingZones.manualDescription
        case "coggan":
            return SettingsContent.TrainingZones.cogganDescriptionShort
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
                    Toggle(SettingsContent.Display.showSleepScore, isOn: $userSettings.showSleepScore)
                        .onChange(of: userSettings.showSleepScore) { _, _ in HapticFeedback.selection() }
                    Toggle(SettingsContent.Display.showRecoveryScore, isOn: $userSettings.showRecoveryScore)
                        .onChange(of: userSettings.showRecoveryScore) { _, _ in HapticFeedback.selection() }
                    Toggle(SettingsContent.Display.showHealthData, isOn: $userSettings.showHealthData)
                        .onChange(of: userSettings.showHealthData) { _, _ in HapticFeedback.selection() }
                } header: {
                    Text(SettingsContent.Display.visibilityTitle)
                } footer: {
                    Text(SettingsContent.Display.visibilityDescription)
                }
                
                Section {
                    Toggle(SettingsContent.Display.metricUnits, isOn: $userSettings.useMetricUnits)
                        .onChange(of: userSettings.useMetricUnits) { _, _ in HapticFeedback.selection() }
                    Toggle(SettingsContent.Display.use24Hour, isOn: $userSettings.use24HourTime)
                        .onChange(of: userSettings.use24HourTime) { _, _ in HapticFeedback.selection() }
                } header: {
                    Text(SettingsContent.Display.unitsTitle)
                } footer: {
                    Text(SettingsContent.Display.unitsDescription)
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
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Authorization Status
                Section {
                    HStack {
                        Image(systemName: notificationManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(notificationManager.isAuthorized ? .green : .orange)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(SettingsContent.Notifications.permission)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(notificationManager.authorizationStatus.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !notificationManager.isAuthorized {
                            Button(SettingsContent.Notifications.enable) {
                                Task {
                                    let granted = await notificationManager.requestAuthorization()
                                    if !granted {
                                        showingPermissionAlert = true
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } footer: {
                    if !notificationManager.isAuthorized {
                        Text(SettingsContent.Notifications.permissionFooter)
                    }
                }
                
                Section {
                    Toggle(SettingsContent.Notifications.sleepReminders, isOn: $userSettings.sleepReminders)
                        .disabled(!notificationManager.isAuthorized)
                        .onChange(of: userSettings.sleepReminders) { _, _ in HapticFeedback.selection() }
                    
                    if userSettings.sleepReminders {
                        DatePicker(SettingsContent.Notifications.reminderTime, selection: $userSettings.sleepReminderTime, displayedComponents: .hourAndMinute)
                            .disabled(!notificationManager.isAuthorized)
                    }
                } header: {
                    Text(SettingsContent.Notifications.sleepReminders)
                } footer: {
                    Text(SettingsContent.Notifications.sleepRemindersDescription)
                }
                
                Section {
                    Toggle(SettingsContent.Notifications.recoveryAlerts, isOn: $userSettings.recoveryAlerts)
                        .disabled(!notificationManager.isAuthorized)
                        .onChange(of: userSettings.recoveryAlerts) { _, _ in HapticFeedback.selection() }
                } header: {
                    Text(SettingsContent.Notifications.recoveryAlerts)
                } footer: {
                    Text(SettingsContent.Notifications.recoveryAlertsDescription)
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
            .alert(SettingsContent.Notifications.permissionDenied, isPresented: $showingPermissionAlert) {
                Button(CommonContent.Actions.ok, role: .cancel) { }
                Button(SettingsContent.Notifications.openSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(SettingsContent.Notifications.permissionDeniedMessage)
            }
            .task {
                await notificationManager.checkAuthorizationStatus()
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
