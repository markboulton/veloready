//
//  AthleteZonesSettingsView.swift
//  VeloReady
//
//  Redesigned settings view for athlete zones
//  PRO: Adaptive, Manual, or Coggan zones
//  FREE: Coggan zones only with editable FTP/Max HR
//

import SwiftUI

struct AthleteZonesSettingsView: View {
    @ObservedObject private var profileManager = AthleteProfileManager.shared
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    
    @State private var editingFTP: String = ""
    @State private var editingMaxHR: String = ""
    @State private var editingPowerZones: [String] = []
    @State private var editingHRZones: [String] = []
    @State private var showRecomputeConfirmation = false
    
    var body: some View {
        List {
            // Athlete Profile Summary
            profileSummarySection
            
            // Power Zones
            powerZonesSection
            
            // Heart Rate Zones
            hrZonesSection
            
            // Actions (if needed)
            if proConfig.hasProAccess {
                proActionsSection
            }
        }
        .navigationTitle("Athlete Zones")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeEditingStates()
            ensureCorrectDefaultsForTier()
        }
    }
    
    // MARK: - Profile Summary
    
    private var profileSummarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // FTP Display/Edit
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FTP")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if canEditFTP {
                            TextField("Enter FTP", text: $editingFTP)
                                .keyboardType(.numberPad)
                                .font(.title2)
                                .fontWeight(.bold)
                                .onSubmit {
                                    saveFTP()
                                }
                        } else {
                            Text("\(Int(profileManager.profile.ftp ?? 0)) W")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    Spacer()
                    
                    sourceIndicator(profileManager.profile.ftpSource)
                }
                
                Divider()
                
                // Max HR Display/Edit
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Max HR")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if canEditMaxHR {
                            TextField("Enter Max HR", text: $editingMaxHR)
                                .keyboardType(.numberPad)
                                .font(.title2)
                                .fontWeight(.bold)
                                .onSubmit {
                                    saveMaxHR()
                                }
                        } else {
                            Text("\(Int(profileManager.profile.maxHR ?? 0)) bpm")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    Spacer()
                    
                    sourceIndicator(profileManager.profile.hrZonesSource)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Athlete Profile")
        } footer: {
            profileFooterText
        }
    }
    
    // MARK: - Power Zones
    
    private var powerZonesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Zone Source Picker (PRO only)
                if proConfig.hasProAccess {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Zone Source")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Power Zone Source", selection: Binding(
                            get: { profileManager.profile.ftpSource },
                            set: { newSource in
                                handlePowerSourceChange(newSource)
                            }
                        )) {
                            Text("Coggan").tag(AthleteProfile.ZoneSource.coggan)
                            Text("Manual").tag(AthleteProfile.ZoneSource.manual)
                            Text("Adaptive").tag(AthleteProfile.ZoneSource.computed)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Divider()
                }
                
                // Zone List
                if let zones = currentPowerZones, zones.count > 1 {
                    ForEach(0..<zones.count-1, id: \.self) { index in
                        powerZoneRow(index: index, zones: zones)
                    }
                } else {
                    Text("No power zones available")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Power Training Zones")
        } footer: {
            powerZonesFooterText
        }
    }
    
    // MARK: - Heart Rate Zones
    
    private var hrZonesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Zone Source Picker (PRO only)
                if proConfig.hasProAccess {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Zone Source")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("HR Zone Source", selection: Binding(
                            get: { profileManager.profile.hrZonesSource },
                            set: { newSource in
                                handleHRSourceChange(newSource)
                            }
                        )) {
                            Text("Coggan").tag(AthleteProfile.ZoneSource.coggan)
                            Text("Manual").tag(AthleteProfile.ZoneSource.manual)
                            Text("Adaptive").tag(AthleteProfile.ZoneSource.computed)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Divider()
                }
                
                // Zone List
                if let zones = currentHRZones, zones.count > 1 {
                    ForEach(0..<zones.count-1, id: \.self) { index in
                        hrZoneRow(index: index, zones: zones)
                    }
                } else {
                    Text("No HR zones available")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Heart Rate Training Zones")
        } footer: {
            hrZonesFooterText
        }
    }
    
    // MARK: - PRO Actions
    
    private var proActionsSection: some View {
        Section {
            if profileManager.profile.ftpSource != .computed || profileManager.profile.hrZonesSource != .computed {
                Button {
                    showRecomputeConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset to Adaptive Zones")
                    }
                }
                .alert("Reset to Adaptive Zones?", isPresented: $showRecomputeConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset") {
                        resetToAdaptive()
                    }
                } message: {
                    Text("This will reset your zones to adaptive computation based on your performance data.")
                }
            }
        }
    }
    
    // MARK: - Zone Row Views
    
    private func powerZoneRow(index: Int, zones: [Double]) -> some View {
        let lowerBound = Int(zones[index])
        let upperBound = index < zones.count - 1 ? Int(zones[index + 1]) : 999
        let zoneName = powerZoneName(index: index)
        
        return HStack {
            // Zone number and name
            VStack(alignment: .leading, spacing: 2) {
                Text("Zone \(index + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Text(zoneName)
                    .font(.subheadline)
            }
            
            Spacer()
            
            // Zone range
            if canEditPowerZones && index > 0 { // Don't allow editing Zone 1 lower bound (always 0)
                TextField("", text: Binding(
                    get: { editingPowerZones.indices.contains(index) ? editingPowerZones[index] : "\(lowerBound)" },
                    set: { newValue in
                        if editingPowerZones.indices.contains(index) {
                            editingPowerZones[index] = newValue
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .onSubmit {
                    savePowerZones()
                }
            } else {
                Text("\(lowerBound)")
                    .fontWeight(.medium)
            }
            
            Text("-")
                .foregroundColor(.secondary)
            
            Text(index == zones.count - 2 ? "Max" : "\(upperBound)")
                .fontWeight(.medium)
            
            Text("W")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func hrZoneRow(index: Int, zones: [Double]) -> some View {
        let lowerBound = Int(zones[index])
        let upperBound = index < zones.count - 1 ? Int(zones[index + 1]) : 999
        let zoneName = hrZoneName(index: index)
        
        return HStack {
            // Zone number and name
            VStack(alignment: .leading, spacing: 2) {
                Text("Zone \(index + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Text(zoneName)
                    .font(.subheadline)
            }
            
            Spacer()
            
            // Zone range
            if canEditHRZones && index > 0 { // Don't allow editing Zone 1 lower bound (always 0)
                TextField("", text: Binding(
                    get: { editingHRZones.indices.contains(index) ? editingHRZones[index] : "\(lowerBound)" },
                    set: { newValue in
                        if editingHRZones.indices.contains(index) {
                            editingHRZones[index] = newValue
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .onSubmit {
                    saveHRZones()
                }
            } else {
                Text("\(lowerBound)")
                    .fontWeight(.medium)
            }
            
            Text("-")
                .foregroundColor(.secondary)
            
            Text(index == zones.count - 2 ? "Max" : "\(upperBound)")
                .fontWeight(.medium)
            
            Text("bpm")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Views
    
    private func sourceIndicator(_ source: AthleteProfile.ZoneSource) -> some View {
        let (text, color) = sourceInfo(source)
        return Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
    
    private func sourceInfo(_ source: AthleteProfile.ZoneSource) -> (String, Color) {
        switch source {
        case .computed:
            return ("Adaptive", .blue)
        case .manual:
            return ("Manual", .orange)
        case .coggan:
            return ("Coggan", .green)
        case .intervals:
            return ("Intervals", .purple) // Deprecated but kept for compatibility
        }
    }
    
    // MARK: - Computed Properties
    
    private var canEditFTP: Bool {
        // All modes except Adaptive allow FTP editing
        return profileManager.profile.ftpSource != .computed
    }
    
    private var canEditMaxHR: Bool {
        // All modes except Adaptive allow Max HR editing
        return profileManager.profile.hrZonesSource != .computed
    }
    
    private var canEditPowerZones: Bool {
        // Only Manual mode allows editing individual zones
        return profileManager.profile.ftpSource == .manual
    }
    
    private var canEditHRZones: Bool {
        // Only Manual mode allows editing individual zones
        return profileManager.profile.hrZonesSource == .manual
    }
    
    private var currentPowerZones: [Double]? {
        profileManager.profile.powerZones
    }
    
    private var currentHRZones: [Double]? {
        profileManager.profile.hrZones
    }
    
    private var profileFooterText: Text {
        if !proConfig.hasProAccess {
            return Text("FREE tier: Edit FTP and Max HR to adjust your Coggan zones. Upgrade to PRO for adaptive zones computed from your performance data.")
        }
        
        switch profileManager.profile.ftpSource {
        case .computed:
            return Text("Adaptive zones are computed from your performance data using modern sports science algorithms. Values update automatically as your fitness changes.")
        case .coggan:
            return Text("Coggan zones use the standard 7-zone model. Edit FTP or Max HR above to adjust all zones proportionally.")
        case .manual:
            return Text("Manual mode allows full control. Edit FTP, Max HR, and individual zone boundaries.")
        case .intervals:
            return Text("Legacy mode - switch to Coggan or Manual for better control.")
        }
    }
    
    private var powerZonesFooterText: Text {
        switch profileManager.profile.ftpSource {
        case .computed:
            return Text("Zones automatically computed from your power-duration curve and performance distribution.")
        case .coggan:
            return Text("Standard Coggan 7-zone model based on FTP. Zones update automatically when you change FTP.")
        case .manual:
            return Text("Tap any zone boundary to edit. Changes are saved automatically.")
        case .intervals:
            return Text("Legacy mode - switch to Coggan or Manual to customize zones.")
        }
    }
    
    private var hrZonesFooterText: Text {
        switch profileManager.profile.hrZonesSource {
        case .computed:
            if let lthr = profileManager.profile.lthr {
                return Text("Zones anchored to lactate threshold (\(Int(lthr)) bpm) detected from sustained efforts.")
            }
            return Text("Zones computed from max HR with adaptive threshold detection.")
        case .coggan:
            return Text("Standard Coggan 7-zone model based on Max HR. Zones update automatically when you change Max HR.")
        case .manual:
            return Text("Tap any zone boundary to edit. Changes are saved automatically.")
        case .intervals:
            return Text("Legacy mode - switch to Coggan or Manual to customize zones.")
        }
    }
    
    // MARK: - Zone Names
    
    private func powerZoneName(index: Int) -> String {
        switch index {
        case 0: return "Active Recovery"
        case 1: return "Endurance"
        case 2: return "Tempo"
        case 3: return "Lactate Threshold"
        case 4: return "VO2 Max"
        case 5: return "Anaerobic"
        case 6: return "Neuromuscular"
        default: return "Zone \(index + 1)"
        }
    }
    
    private func hrZoneName(index: Int) -> String {
        switch index {
        case 0: return "Recovery"
        case 1: return "Aerobic"
        case 2: return "Tempo"
        case 3: return "Lactate Threshold"
        case 4: return "VO2 Max"
        case 5: return "Anaerobic"
        case 6: return "Max"
        default: return "Zone \(index + 1)"
        }
    }
    
    // MARK: - Actions
    
    private func initializeEditingStates() {
        editingFTP = "\(Int(profileManager.profile.ftp ?? 0))"
        editingMaxHR = "\(Int(profileManager.profile.maxHR ?? 0))"
        
        if let zones = profileManager.profile.powerZones {
            editingPowerZones = zones.map { "\(Int($0))" }
        }
        
        if let zones = profileManager.profile.hrZones {
            editingHRZones = zones.map { "\(Int($0))" }
        }
    }
    
    private func ensureCorrectDefaultsForTier() {
        // FREE users should always use Coggan zones
        if !proConfig.hasProAccess {
            if profileManager.profile.ftpSource == .computed {
                profileManager.profile.ftpSource = .coggan
                // Generate Coggan zones if we have FTP
                if let ftp = profileManager.profile.ftp, ftp > 0 {
                    profileManager.profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp)
                }
                profileManager.save()
            }
            
            if profileManager.profile.hrZonesSource == .computed {
                profileManager.profile.hrZonesSource = .coggan
                // Generate Coggan zones if we have Max HR
                if let maxHR = profileManager.profile.maxHR, maxHR > 0 {
                    profileManager.profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: maxHR)
                }
                profileManager.save()
            }
        }
    }
    
    private func saveFTP() {
        guard let ftp = Double(editingFTP), ftp > 0 else { return }
        
        profileManager.profile.ftp = ftp
        
        // Regenerate zones if in Coggan mode
        if profileManager.profile.ftpSource == .coggan {
            profileManager.profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp)
        }
        
        profileManager.save()
        Logger.data("💾 Saved FTP: \(Int(ftp))W")
    }
    
    private func saveMaxHR() {
        guard let maxHR = Double(editingMaxHR), maxHR > 0 else { return }
        
        profileManager.profile.maxHR = maxHR
        
        // Regenerate zones if in Coggan mode
        if profileManager.profile.hrZonesSource == .coggan {
            profileManager.profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: maxHR)
        }
        
        profileManager.save()
        Logger.data("💾 Saved Max HR: \(Int(maxHR)) bpm")
    }
    
    private func savePowerZones() {
        let zones = editingPowerZones.compactMap { Double($0) }
        guard zones.count >= 7 else { return }
        
        profileManager.profile.powerZones = zones
        profileManager.save()
        Logger.data("💾 Saved custom power zones")
    }
    
    private func saveHRZones() {
        let zones = editingHRZones.compactMap { Double($0) }
        guard zones.count >= 7 else { return }
        
        profileManager.profile.hrZones = zones
        profileManager.save()
        Logger.data("💾 Saved custom HR zones")
    }
    
    private func handlePowerSourceChange(_ newSource: AthleteProfile.ZoneSource) {
        profileManager.profile.ftpSource = newSource
        
        switch newSource {
        case .computed:
            // Trigger adaptive computation
            Logger.data("🔄 Switching to adaptive power zones - fetching activities...")
            // Note: Computation happens in background via CacheManager
        case .coggan:
            // Generate Coggan zones from current FTP
            if let ftp = profileManager.profile.ftp, ftp > 0 {
                profileManager.profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp)
            }
        case .manual:
            // Keep current zones, allow editing
            break
        case .intervals:
            // Sync from Intervals.icu
            break
        }
        
        profileManager.save()
        initializeEditingStates()
    }
    
    private func handleHRSourceChange(_ newSource: AthleteProfile.ZoneSource) {
        profileManager.profile.hrZonesSource = newSource
        
        switch newSource {
        case .computed:
            // Trigger adaptive computation
            Logger.data("🔄 Switching to adaptive HR zones - fetching activities...")
            // Note: Computation happens in background via CacheManager
        case .coggan:
            // Generate Coggan zones from current Max HR
            if let maxHR = profileManager.profile.maxHR, maxHR > 0 {
                profileManager.profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: maxHR)
            }
        case .manual:
            // Keep current zones, allow editing
            break
        case .intervals:
            // Sync from Intervals.icu
            break
        }
        
        profileManager.save()
        initializeEditingStates()
    }
    
    private func resetToAdaptive() {
        profileManager.profile.ftpSource = .computed
        profileManager.profile.hrZonesSource = .computed
        profileManager.save()
        
        Logger.data("🔄 Reset to adaptive zones - computation will occur on next data refresh")
    }
}
