//
//  AthleteZonesSettingsView.swift
//  Rideready
//
//  Settings view for viewing and overriding athlete zones
//

import SwiftUI

struct AthleteZonesSettingsView: View {
    @ObservedObject private var profileManager = AthleteProfileManager.shared
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @EnvironmentObject var intervalsAPIClient: IntervalsAPIClient
    
    @State private var isEditingFTP = false
    @State private var isEditingMaxHR = false
    @State private var editedFTP: String = ""
    @State private var editedMaxHR: String = ""
    @State private var showRecomputeConfirmation = false
    
    var body: some View {
        List {
            // Summary Section
            summarySection
            
            // Power Zones Section
            powerZonesSection
            
            // Heart Rate Zones Section
            hrZonesSection
            
            // Additional Metrics Section
            additionalMetricsSection
            
            // Actions Section
            actionsSection
        }
        .navigationTitle(AthleteZonesContent.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(AthleteZonesContent.recompute, isPresented: $showRecomputeConfirmation) {
            Button(AthleteZonesContent.cancel, role: .cancel) { }
            Button(AthleteZonesContent.recompute) {
                recomputeZones()
            }
        } message: {
            Text(AthleteZonesContent.recomputeMessage)
        }
        .task {
            // Trigger recompute on first load if no data
            if profileManager.profile.ftp == nil || profileManager.profile.ftp == 0 {
                Logger.data("No FTP data found, triggering initial recompute...")
                recomputeZones()
            }
        }
    }
    
    // MARK: - Sections
    
    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Adaptive FTP
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(ColorScale.purpleAccent)
                    VStack(alignment: .leading) {
                        HStack(spacing: 6) {
                            Text(AthleteZonesContent.Summary.adaptiveFTP)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if proConfig.hasProAccess {
                                Text(AthleteZonesContent.Summary.proBadge)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(ColorScale.purpleAccent)
                                    .cornerRadius(3)
                            }
                        }
                        Text("\(Int(profileManager.profile.ftp ?? 0)) W")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    if proConfig.hasProAccess {
                        sourceLabel(profileManager.profile.ftpSource)
                    }
                }
                
                Divider()
                
                // Max HR
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(ColorScale.pinkAccent)
                    VStack(alignment: .leading) {
                        Text(AthleteZonesContent.Summary.maxHR)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(profileManager.profile.maxHR ?? 0)) bpm")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    sourceLabel(profileManager.profile.hrZonesSource)
                }
                
                // Advanced Metrics Row 1
                if let wPrime = profileManager.profile.wPrime, let vo2max = profileManager.profile.vo2maxEstimate {
                    Divider()
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("W' (Anaerobic)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(Int(wPrime / 1000))kJ")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("VO2max Est.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(Int(vo2max)) ml/kg/min")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // Data Quality
                if let quality = profileManager.profile.dataQuality {
                    Divider()
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(qualityColor(quality.confidenceScore))
                        VStack(alignment: .leading) {
                            Text("Data Quality")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(Int(quality.confidenceScore * 100))% confidence")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Text("\(quality.sampleSize) activities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Last Computed
                if let lastComputed = profileManager.profile.lastComputedFromActivities {
                    Divider()
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                        Text("Last computed:")
                        Spacer()
                        Text(lastComputed, style: .relative)
                            .foregroundColor(.secondary)
                        Text("ago")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Athlete Profile")
        } footer: {
            if profileManager.profile.ftpSource == .computed {
                Text("Adaptive FTP uses modern sports science (Leo et al. 2022) to compute your threshold from actual performance data.")
            }
        }
    }
    
    private func qualityColor(_ score: Double) -> Color {
        if score >= 0.7 { return .green }
        if score >= 0.5 { return .orange }
        return .red
    }
    
    private var powerZonesSection: some View {
        Section {
            // Zone Source Picker - PRO feature
            if proConfig.hasProAccess {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Zone Source")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Power Zone Source", selection: $profileManager.profile.ftpSource) {
                        Text("Adaptive (Recommended)").tag(AthleteProfile.ZoneSource.computed)
                        Text("Manual").tag(AthleteProfile.ZoneSource.manual)
                        Text("Coggan").tag(AthleteProfile.ZoneSource.coggan)
                        Text("Intervals.icu").tag(AthleteProfile.ZoneSource.intervals)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: profileManager.profile.ftpSource) { _, newSource in
                        handlePowerSourceChange(newSource)
                    }
                    
                    // Description based on source
                    Text(powerSourceDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Show FTP input when override is enabled
                if profileManager.profile.ftpSource == .manual {
                    if isEditingFTP {
                        HStack {
                            Text("FTP")
                            Spacer()
                            TextField("Watts", text: $editedFTP)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .textFieldStyle(.roundedBorder)
                            Text("W")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Button(AthleteZonesContent.cancel) {
                                isEditingFTP = false
                                // Reset toggle
                                profileManager.resetFTPToComputed()
                            }
                            Spacer()
                            Button(AthleteZonesContent.save) {
                                saveFTP()
                            }
                            .fontWeight(.semibold)
                            .disabled(editedFTP.isEmpty)
                        }
                    } else {
                        HStack {
                            Text("FTP")
                            Spacer()
                            Text("\(Int(profileManager.profile.ftp ?? 0)) W")
                                .foregroundColor(ColorScale.purpleAccent)
                                .fontWeight(.medium)
                            Button(AthleteZonesContent.edit) {
                                startEditingFTP()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
            
            Divider()
            
            // Computed Zones (Read-only)
            Text("Coggan Power Zones")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if let zones = profileManager.profile.powerZones {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, boundary in
                    if index < zones.count - 1 {
                        let nextBoundary = zones[index + 1]
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Zone \(index + 1)")
                                    .font(.subheadline)
                                Text(powerZoneName(index))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(Int(boundary)) - \(Int(nextBoundary)) W")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .monospacedDigit()
                        }
                    }
                }
            } else {
                Text("No power zones configured")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        } header: {
            Text("Power Training Zones")
        } footer: {
            if profileManager.profile.ftpSource == .manual {
                Text("⚠️ Manual override active. Zones computed from your override value.")
            } else {
                Text("Zones automatically computed using Coggan 7-zone model from Adaptive FTP.")
            }
        }
    }
    
    private var hrZonesSection: some View {
        Section {
            // Zone Source Picker - PRO feature
            if proConfig.hasProAccess {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Zone Source")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("HR Zone Source", selection: $profileManager.profile.hrZonesSource) {
                        Text("Adaptive (Recommended)").tag(AthleteProfile.ZoneSource.computed)
                        Text("Manual").tag(AthleteProfile.ZoneSource.manual)
                        Text("Coggan").tag(AthleteProfile.ZoneSource.coggan)
                        Text("Intervals.icu").tag(AthleteProfile.ZoneSource.intervals)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: profileManager.profile.hrZonesSource) { _, newSource in
                        handleHRSourceChange(newSource)
                    }
                    
                    // Description based on source
                    Text(hrSourceDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Show Max HR input when override is enabled
                if profileManager.profile.hrZonesSource == .manual {
                    if isEditingMaxHR {
                        HStack {
                            Text("Max HR")
                            Spacer()
                            TextField("BPM", text: $editedMaxHR)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .textFieldStyle(.roundedBorder)
                            Text("bpm")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Button(AthleteZonesContent.cancel) {
                                isEditingMaxHR = false
                                // Reset toggle
                                profileManager.resetMaxHRToComputed()
                            }
                            Spacer()
                            Button(AthleteZonesContent.save) {
                                saveMaxHR()
                            }
                            .fontWeight(.semibold)
                            .disabled(editedMaxHR.isEmpty)
                        }
                    } else {
                        HStack {
                            Text("Max HR")
                            Spacer()
                            Text("\(Int(profileManager.profile.maxHR ?? 0)) bpm")
                                .foregroundColor(ColorScale.pinkAccent)
                                .fontWeight(.medium)
                            Button(AthleteZonesContent.edit) {
                                startEditingMaxHR()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
            
            Divider()
            
            // LTHR Display (if available)
            if let lthr = profileManager.profile.lthr {
                HStack {
                    Text("LTHR (Detected)")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(lthr)) bpm")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .monospacedDigit()
                }
                Divider()
            }
            
            // Computed Zones (Read-only)
            Text("Heart Rate Training Zones")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if let zones = profileManager.profile.hrZones {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, boundary in
                    if index < zones.count - 1 {
                        let nextBoundary = zones[index + 1]
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Zone \(index + 1)")
                                    .font(.subheadline)
                                Text(hrZoneName(index))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(Int(boundary)) - \(Int(nextBoundary)) bpm")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .monospacedDigit()
                        }
                    }
                }
            } else {
                Text("No heart rate zones configured")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        } header: {
            Text("Heart Rate Training Zones")
        } footer: {
            if profileManager.profile.hrZonesSource == .manual {
                Text("⚠️ Manual Max HR override active. Zones are computed from your override value. Tap 'Reset to Computed' to use adaptive detection.")
            } else if profileManager.profile.lthr != nil {
                Text("Zones are LTHR-anchored using lactate threshold detected from your sustained efforts. These zones are read-only and update as your fitness changes.")
            } else {
                Text("Zones are computed from your observed max HR with 2% buffer. These zones are read-only and update as your fitness changes.")
            }
        }
    }
    
    private var additionalMetricsSection: some View {
        Section {
            // Power Profile
            if let powerProfile = profileManager.profile.powerProfile {
                if let power5min = powerProfile.power5min {
                    HStack {
                        Text("5-min Power")
                        Spacer()
                        Text("\(Int(power5min)) W")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                
                if let power20min = powerProfile.power20min {
                    HStack {
                        Text("20-min Power")
                        Spacer()
                        Text("\(Int(power20min)) W")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            
            // Physiological Metrics
            if let restingHR = profileManager.profile.restingHR {
                HStack {
                    Text("Resting HR")
                    Spacer()
                    Text("\(Int(restingHR)) bpm")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            
            if let weight = profileManager.profile.weight {
                HStack {
                    Text("Weight")
                    Spacer()
                    Text(String(format: "%.1f kg", weight))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            
            // FTP per kg (if weight available)
            if let ftp = profileManager.profile.ftp, let weight = profileManager.profile.weight, weight > 0 {
                HStack {
                    Text("FTP/kg")
                    Spacer()
                    Text(String(format: "%.2f W/kg", ftp / weight))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
        } header: {
            Text("Performance Metrics")
        } footer: {
            Text("Automatically computed from your performance data and updated from recent activities.")
        }
    }
    
    private var actionsSection: some View {
        Section {
            if profileManager.profile.ftpSource == .manual || profileManager.profile.hrZonesSource == .manual {
                Button(action: {
                    profileManager.resetToComputed()
                    // Trigger recompute
                    Task {
                        await fetchAndRecompute()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset to Computed Values")
                    }
                }
            }
            
            Button(action: {
                showRecomputeConfirmation = true
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Recompute from Activities")
                }
            }
        } footer: {
            Text("Zones are automatically recomputed when new activities sync from Intervals.icu.")
        }
    }
    
    // MARK: - Helper Views
    
    private func sourceLabel(_ source: AthleteProfile.ZoneSource) -> some View {
        let (text, color) = sourceLabelInfo(source)
        return Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
    
    private func sourceLabelInfo(_ source: AthleteProfile.ZoneSource) -> (String, Color) {
        switch source {
        case .computed:
            return ("Computed", .blue)
        case .manual:
            return ("Manual", .orange)
        case .intervals:
            return ("Intervals.icu", .green)
        case .coggan:
            return ("Coggan", .purple)
        }
    }
    
    // MARK: - Computed Properties
    
    private var powerSourceDescription: String {
        switch profileManager.profile.ftpSource {
        case .computed:
            return "Zones computed from your performance data using modern sports science."
        case .manual:
            return "Enter your FTP manually. Zones will be calculated from your input."
        case .coggan:
            return "Standard Coggan zones based on your FTP."
        case .intervals:
            return "Sync zones from your Intervals.icu profile."
        }
    }
    
    private var hrSourceDescription: String {
        switch profileManager.profile.hrZonesSource {
        case .computed:
            return "Zones computed from your performance data with LTHR detection."
        case .manual:
            return "Enter your Max HR manually. Zones will be calculated from your input."
        case .coggan:
            return "Standard Coggan HR zones based on your Max HR."
        case .intervals:
            return "Sync zones from your Intervals.icu profile."
        }
    }
    
    // MARK: - Zone Names
    
    private func hrZoneName(_ index: Int) -> String {
        let names = ["Recovery", "Endurance", "Tempo", "Threshold", "VO2 Max", "Anaerobic", "Max"]
        return names[index % names.count]
    }
    
    private func powerZoneName(_ index: Int) -> String {
        let names = ["Active Recovery", "Endurance", "Tempo", "Threshold", "VO2 Max", "Anaerobic", "Neuromuscular"]
        return names[index % names.count]
    }
    
    // MARK: - Actions
    
    private func startEditingFTP() {
        editedFTP = String(Int(profileManager.profile.ftp ?? 0))
        isEditingFTP = true
    }
    
    private func saveFTP() {
        guard let ftp = Double(editedFTP), ftp > 0 else { return }
        
        // Generate default zones from FTP
        let zones = AthleteProfileManager.generatePowerZones(ftp: ftp)
        profileManager.setManualFTP(ftp, zones: zones)
        
        isEditingFTP = false
    }
    
    private func startEditingMaxHR() {
        editedMaxHR = String(Int(profileManager.profile.maxHR ?? 0))
        isEditingMaxHR = true
    }
    
    private func saveMaxHR() {
        guard let maxHR = Double(editedMaxHR), maxHR > 0 else { return }
        
        // Generate default zones from Max HR
        let zones = AthleteProfileManager.generateHRZones(maxHR: maxHR)
        profileManager.setManualMaxHR(maxHR, zones: zones)
        
        isEditingMaxHR = false
    }
    
    private func recomputeZones() {
        Task {
            await fetchAndRecompute()
        }
    }
    
    private func fetchAndRecompute() async {
        do {
            Logger.data("Starting manual recomputation...")
            
            // Fetch 120 days of activities with high limit for accurate zone computation
            let activities = try await intervalsAPIClient.fetchRecentActivities(limit: 300, daysBack: 120)
            
            Logger.data("Fetched \(activities.count) activities for recomputation (last 120 days)")
            
            // Recompute zones (already on main actor in SwiftUI view)
            await profileManager.computeFromActivities(activities)
            
            Logger.data("✅ Recomputation complete")
            
        } catch {
            Logger.error("Failed to fetch activities for recomputation: \(error)")
        }
    }
    
    private func handlePowerSourceChange(_ source: AthleteProfile.ZoneSource) {
        switch source {
        case .manual:
            // Show manual input UI
            startEditingFTP()
        case .coggan:
            // Coggan zones are applied automatically via computed property
            // No immediate action needed
            profileManager.save()
        case .intervals:
            // Trigger Intervals.icu sync
            Task {
                // TODO: Implement Intervals.icu zone sync
                Logger.data("Intervals.icu zone sync not yet implemented")
            }
        case .computed:
            // Zones will recompute on next activity sync
            // No immediate action needed
            profileManager.save()
        }
    }
    
    private func handleHRSourceChange(_ source: AthleteProfile.ZoneSource) {
        switch source {
        case .manual:
            // Show manual input UI
            startEditingMaxHR()
        case .coggan:
            // Coggan zones are applied automatically via computed property
            // No immediate action needed
            profileManager.save()
        case .intervals:
            // Trigger Intervals.icu sync
            Task {
                // TODO: Implement Intervals.icu zone sync
                Logger.data("Intervals.icu zone sync not yet implemented")
            }
        case .computed:
            // Zones will recompute on next activity sync
            // No immediate action needed
            profileManager.save()
        }
    }
}

#Preview {
    NavigationStack {
        AthleteZonesSettingsView()
            .environmentObject(IntervalsAPIClient.shared)
    }
}
