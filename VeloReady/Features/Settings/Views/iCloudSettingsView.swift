import SwiftUI

/// View for managing iCloud sync settings and data restoration
struct iCloudSettingsView: View {
    @StateObject private var syncService = iCloudSyncService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingRestoreConfirmation = false
    @State private var showingRestoreSuccess = false
    @State private var showingRestoreError = false
    
    var body: some View {
        List {
                // iCloud Status Section
                Section {
                    HStack {
                        Text(SettingsContent.iCloud.title)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if syncService.isCloudAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: Icons.Status.successFill)
                                    .foregroundColor(Color.semantic.success)
                                Text(CommonContent.States.enabled)
                                    .foregroundColor(Color.semantic.success)
                            }
                            .font(.subheadline)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: Icons.Status.errorFill)
                                    .foregroundColor(Color.semantic.error)
                                Text(SettingsContent.iCloud.notAvailable)
                                    .foregroundColor(Color.semantic.error)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    if let lastSync = syncService.lastSyncDate {
                        HStack {
                            Text(SettingsContent.iCloud.lastSync)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(lastSync, style: .relative)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let error = syncService.syncError {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(SettingsContent.iCloud.syncError)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Color.text.error)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(SettingsContent.iCloud.status)
                } footer: {
                    Text(SettingsContent.iCloud.autoSyncDescription)
                }
                
                // Sync Actions Section
                if syncService.isCloudAvailable {
                    Section {
                        Button(action: {
                            Task {
                                await syncService.syncToCloud()
                            }
                        }) {
                            HStack {
                                if syncService.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: Icons.Arrow.clockwise)
                                }
                                
                                Button(SettingsContent.iCloud.syncNow) {
                                }
                            }
                        }
                        .disabled(syncService.isSyncing)
                        
                        Button(action: {
                            showingRestoreConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: Icons.Document.download)
                                Button(SettingsContent.iCloud.restoreFromCloud) {
                                }
                            }
                        }
                        .disabled(syncService.isSyncing)
                    } header: {
                        Text(SettingsContent.iCloud.actions)
                    } footer: {
                        Text(SettingsContent.iCloud.actionsFooter)
                    }
                    
                    // What's Synced Section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            SyncedDataRow(
                                icon: "gearshape.fill",
                                title: SettingsContent.iCloud.userSettings,
                                description: "Sleep targets, zones, display preferences"
                            )
                            
                            Divider()
                            
                            SyncedDataRow(
                                icon: "figure.strengthtraining.traditional",
                                title: SettingsContent.iCloud.strengthData,
                                description: "RPE ratings and muscle group selections"
                            )
                            
                            Divider()
                            
                            SyncedDataRow(
                                icon: "chart.bar.fill",
                                title: SettingsContent.iCloud.workoutMetadata,
                                description: "Exercise tracking and recovery data"
                            )
                            
                            Divider()
                            
                            SyncedDataRow(
                                icon: "heart.fill",
                                title: SettingsContent.iCloud.dailyScores,
                                description: "Recovery, sleep, and strain scores"
                            )
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text(SettingsContent.iCloud.whatSyncs)
                    } footer: {
                        Text(SettingsContent.iCloud.encryptionFooter)
                    }
                } else {
                    // iCloud Not Available Section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: Icons.Status.warningFill)
                                    .foregroundColor(Color.semantic.warning)
                                
                                Text(SettingsContent.iCloud.notAvailableTitle)
                                    .font(.headline)
                            }
                            
                            Text(SettingsContent.iCloud.enableInstructions)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SettingsContent.iCloud.step1)
                                Text(SettingsContent.iCloud.step2)
                                Text(SettingsContent.iCloud.step3)
                                Text(SettingsContent.iCloud.step4)
                                Text(SettingsContent.iCloud.step5)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
        }
        .navigationTitle(iCloudSyncContent.title)
        .navigationBarTitleDisplayMode(.inline)
            .alert(iCloudSyncContent.Alerts.restoreTitle, isPresented: $showingRestoreConfirmation) {
                Button(iCloudSyncContent.Alerts.cancel, role: .cancel) { }
                Button(iCloudSyncContent.Alerts.restoreConfirm, role: .destructive) {
                    Task {
                        do {
                            try await syncService.restoreFromCloud()
                            showingRestoreSuccess = true
                        } catch {
                            showingRestoreError = true
                        }
                    }
                }
            } message: {
                Text(SettingsContent.iCloud.restoreConfirmMessage)
            }
            .alert(SettingsContent.iCloud.restoreSuccessTitle, isPresented: $showingRestoreSuccess) {
                Button(iCloudSyncContent.Alerts.ok, role: .cancel) { }
            } message: {
                Text(SettingsContent.iCloud.restoreSuccessMessage)
            }
            .alert(SettingsContent.iCloud.restoreFailedTitle, isPresented: $showingRestoreError) {
                Button(iCloudSyncContent.Alerts.ok, role: .cancel) { }
            } message: {
                Text(syncService.syncError ?? "Failed to restore data from iCloud. Please try again.")
            }
    }
}

// MARK: - Synced Data Row

struct SyncedDataRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.button.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

struct iCloudSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        iCloudSettingsView()
    }
}
