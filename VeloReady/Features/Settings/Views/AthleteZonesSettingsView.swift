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
    @State private var isEditingFTP = false
    @State private var isEditingMaxHR = false
    
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
        .navigationTitle(SettingsContent.AthleteZones.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeEditingStates()
            ensureCorrectDefaultsForTier()
            
            // Debug logging
            Logger.data("🎯 Athlete Zones Settings:")
            Logger.data("   FTP Source: \(profileManager.profile.ftpSource.rawValue)")
            Logger.data("   HR Source: \(profileManager.profile.hrZonesSource.rawValue)")
            Logger.data("   canEditFTP: \(canEditFTP)")
            Logger.data("   canEditMaxHR: \(canEditMaxHR)")
            Logger.data("   PRO Access: \(proConfig.hasProAccess)")
        }
    }
    
    // MARK: - Profile Summary
    
    private var profileSummarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // FTP Display/Edit
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(SettingsContent.AthleteZones.athlete)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        sourceIndicator(profileManager.profile.ftpSource)
                    }
                    
                    if canEditFTP {
                        if isEditingFTP {
                            HStack {
                                TextField("FTP", text: $editingFTP)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                                
                                Text(CommonContent.Units.watts)
                                    .foregroundColor(.secondary)
                                
                                Button(SettingsContent.AthleteZones.save) {
                                    saveFTP()
                                    isEditingFTP = false
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(editingFTP.isEmpty || Int(editingFTP) == nil)
                                
                                Button(SettingsContent.AthleteZones.cancel) {
                                    editingFTP = "\(Int(profileManager.profile.ftp ?? 0))"
                                    isEditingFTP = false
                                }
                                .buttonStyle(.bordered)
                            }
                        } else {
                            HStack {
                                Text("\(Int(profileManager.profile.ftp ?? 0)) W")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button {
                                    editingFTP = "\(Int(profileManager.profile.ftp ?? 0))"
                                    isEditingFTP = true
                                } label: {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text(SettingsContent.AthleteZones.edit)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(profileManager.profile.ftp ?? 0)) W")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(SettingsContent.AthleteZones.computedFromData)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // Max HR Display/Edit
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(SettingsContent.AthleteZones.maxHR)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        sourceIndicator(profileManager.profile.hrZonesSource)
                    }
                    
                    if canEditMaxHR {
                        if isEditingMaxHR {
                            HStack {
                                TextField("Max HR", text: $editingMaxHR)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                                
                                Text(CommonContent.Units.bpm)
                                    .foregroundColor(.secondary)
                                
                                Button(SettingsContent.AthleteZones.save) {
                                    saveMaxHR()
                                    isEditingMaxHR = false
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(editingMaxHR.isEmpty || Int(editingMaxHR) == nil)
                                
                                Button(SettingsContent.AthleteZones.cancel) {
                                    editingMaxHR = "\(Int(profileManager.profile.maxHR ?? 0))"
                                    isEditingMaxHR = false
                                }
                                .buttonStyle(.bordered)
                            }
                        } else {
                            HStack {
                                Text("\(Int(profileManager.profile.maxHR ?? 0)) bpm")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button {
                                    editingMaxHR = "\(Int(profileManager.profile.maxHR ?? 0))"
                                    isEditingMaxHR = true
                                } label: {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text(SettingsContent.AthleteZones.edit)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(profileManager.profile.maxHR ?? 0)) bpm")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(SettingsContent.AthleteZones.computedFromData)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text(SettingsContent.AthleteZones.athleteProfile)
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
                        Text(SettingsContent.AthleteZones.zoneSource)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker(SettingsContent.AthleteZones.powerSource, selection: Binding(
                            get: { profileManager.profile.ftpSource },
                            set: { newSource in
                                handlePowerSourceChange(newSource)
                            }
                        )) {
                            Text(SettingsContent.AthleteZones.coggan).tag(AthleteProfile.ZoneSource.coggan)
                            Text(SettingsContent.AthleteZones.manual).tag(AthleteProfile.ZoneSource.manual)
                            Text(SettingsContent.AthleteZones.adaptive).tag(AthleteProfile.ZoneSource.computed)
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
                    Text(SettingsContent.AthleteZones.noPowerZones)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text(SettingsContent.AthleteZones.powerTrainingZones)
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
                }
                
                // Zone List
                if let zones = currentHRZones, zones.count > 1 {
                    ForEach(0..<zones.count-1, id: \.self) { index in
                        hrZoneRow(index: index, zones: zones)
                    }
                } else {
                    Text(SettingsContent.AthleteZones.noHRZones)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text(SettingsContent.AthleteZones.heartRateTrainingZones)
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
                        Text(SettingsContent.AthleteZones.resetToAdaptive)
                    }
                }
                .alert(SettingsContent.AthleteZones.resetConfirmTitle, isPresented: $showRecomputeConfirmation) {
                    Button(CommonContent.Actions.cancel, role: .cancel) { }
                    Button(CommonContent.Actions.reset) {
                        resetToAdaptive()
                    }
                } message: {
                    Text(SettingsContent.AthleteZones.resetConfirmMessage)
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
                Text("\(SettingsContent.AthleteZones.zone) \(index + 1)")
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
            
            Text(SettingsContent.AthleteZones.dash)
                .foregroundColor(.secondary)
            
            Text(index == zones.count - 2 ? SettingsContent.AthleteZones.max : "\(upperBound)")
                .fontWeight(.medium)
            
            Text(SettingsContent.AthleteZones.watts)
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
                Text("\(SettingsContent.AthleteZones.zone) \(index + 1)")
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
            
            Text(SettingsContent.AthleteZones.dash)
                .foregroundColor(.secondary)
            
            Text(index == zones.count - 2 ? SettingsContent.AthleteZones.max : "\(upperBound)")
                .fontWeight(.medium)
            
            Text(SettingsContent.AthleteZones.bpm)
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
            return (SettingsContent.AthleteZones.adaptive, .blue)
        case .manual:
            return (SettingsContent.AthleteZones.manual, .orange)
        case .coggan:
            return (SettingsContent.AthleteZones.coggan, .green)
        case .intervals:
            return (SettingsContent.AthleteZones.intervals, .purple) // Deprecated but kept for compatibility
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
            return Text(SettingsContent.AthleteZones.freeFooter)
        }
        
        switch profileManager.profile.ftpSource {
        case .computed:
            return Text(SettingsContent.AthleteZones.adaptiveFooter)
        case .coggan:
            return Text(SettingsContent.AthleteZones.cogganFooter)
        case .manual:
            return Text(SettingsContent.AthleteZones.manualFooter)
        case .intervals:
            return Text(SettingsContent.AthleteZones.legacyFooter)
        }
    }
    
    private var powerZonesFooterText: Text {
        switch profileManager.profile.ftpSource {
        case .computed:
            return Text(SettingsContent.AthleteZones.powerAdaptiveFooter)
        case .coggan:
            return Text(SettingsContent.AthleteZones.powerCogganFooter)
        case .manual:
            return Text(SettingsContent.AthleteZones.powerManualFooter)
        case .intervals:
            return Text(SettingsContent.AthleteZones.powerLegacyFooter)
        }
    }
    
    private var hrZonesFooterText: Text {
        switch profileManager.profile.hrZonesSource {
        case .computed:
            if let lthr = profileManager.profile.lthr {
                return Text("\(SettingsContent.AthleteZones.zonesAnchored) (\(Int(lthr)) \(SettingsContent.AthleteZones.bpm)) \(SettingsContent.AthleteZones.detectedFrom)")
            }
            return Text(SettingsContent.AthleteZones.hrAdaptiveFooter)
        case .coggan:
            return Text(SettingsContent.AthleteZones.hrCogganFooter)
        case .manual:
            return Text(SettingsContent.AthleteZones.hrManualFooter)
        case .intervals:
            return Text(SettingsContent.AthleteZones.hrLegacyFooter)
        }
    }
    
    // MARK: - Zone Names
    
    private func powerZoneName(index: Int) -> String {
        switch index {
        case 0: return SettingsContent.AthleteZones.powerZone1
        case 1: return SettingsContent.AthleteZones.powerZone2
        case 2: return SettingsContent.AthleteZones.powerZone3
        case 3: return SettingsContent.AthleteZones.powerZone4
        case 4: return SettingsContent.AthleteZones.powerZone5
        case 5: return SettingsContent.AthleteZones.powerZone6
        case 6: return SettingsContent.AthleteZones.powerZone7
        default: return "Zone \(index + 1)"
        }
    }
    
    private func hrZoneName(index: Int) -> String {
        switch index {
        case 0: return SettingsContent.AthleteZones.hrZone1
        case 1: return SettingsContent.AthleteZones.hrZone2
        case 2: return SettingsContent.AthleteZones.hrZone3
        case 3: return SettingsContent.AthleteZones.hrZone4
        case 4: return SettingsContent.AthleteZones.hrZone5
        case 5: return SettingsContent.AthleteZones.hrZone6
        case 6: return SettingsContent.AthleteZones.hrZone7
        default: return "Zone \(index + 1)"
        }
    }
    
    // MARK: - Actions
    
    private func initializeEditingStates() {
        editingFTP = "\(Int(profileManager.profile.ftp ?? 0))"
        editingMaxHR = "\(Int(profileManager.profile.maxHR ?? 0))"
        isEditingFTP = false
        isEditingMaxHR = false
        
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
