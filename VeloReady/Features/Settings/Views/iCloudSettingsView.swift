import SwiftUI

/// View for managing iCloud sync settings and data restoration
struct iCloudSettingsView: View {
    @StateObject private var syncService = iCloudSyncService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingRestoreConfirmation = false
    @State private var showingRestoreSuccess = false
    @State private var showingRestoreError = false
    
    var body: some View {
        NavigationView {
            List {
                // iCloud Status Section
                Section {
                    HStack {
                        Text("iCloud Status")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if syncService.isCloudAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.semantic.success)
                                Text("Available")
                                    .foregroundColor(Color.semantic.success)
                            }
                            .font(.subheadline)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.semantic.error)
                                Text("Not Available")
                                    .foregroundColor(Color.semantic.error)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    if let lastSync = syncService.lastSyncDate {
                        HStack {
                            Text("Last Sync")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(lastSync, style: .relative)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let error = syncService.syncError {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sync Error")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Color.text.error)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Status")
                } footer: {
                    Text("iCloud automatically syncs your settings, workout data, and strength exercise logs across all your devices.")
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
                                    Image(systemName: "arrow.clockwise.icloud")
                                }
                                
                                Text("Sync Now")
                            }
                        }
                        .disabled(syncService.isSyncing)
                        
                        Button(action: {
                            showingRestoreConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("Restore from iCloud")
                            }
                        }
                        .disabled(syncService.isSyncing)
                    } header: {
                        Text("Actions")
                    } footer: {
                        Text("Manually sync your data to iCloud or restore from your iCloud backup.")
                    }
                    
                    // What's Synced Section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            SyncedDataRow(
                                icon: "gearshape.fill",
                                title: "User Settings",
                                description: "Sleep targets, zones, display preferences"
                            )
                            
                            Divider()
                            
                            SyncedDataRow(
                                icon: "figure.strengthtraining.traditional",
                                title: "Strength Exercise Data",
                                description: "RPE ratings and muscle group selections"
                            )
                            
                            Divider()
                            
                            SyncedDataRow(
                                icon: "chart.bar.fill",
                                title: "Workout Metadata",
                                description: "Exercise tracking and recovery data"
                            )
                            
                            Divider()
                            
                            SyncedDataRow(
                                icon: "heart.fill",
                                title: "Daily Scores",
                                description: "Recovery, sleep, and strain scores"
                            )
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("What's Synced")
                    } footer: {
                        Text("All data is encrypted and stored securely in your private iCloud account.")
                    }
                } else {
                    // iCloud Not Available Section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.semantic.warning)
                                
                                Text("iCloud Not Available")
                                    .font(.headline)
                            }
                            
                            Text("To enable iCloud sync:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("1. Open Settings app")
                                Text("2. Tap your name at the top")
                                Text("3. Tap iCloud")
                                Text("4. Enable iCloud Drive")
                                Text("5. Ensure VeloReady has iCloud access")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Restore from iCloud", isPresented: $showingRestoreConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Restore", role: .destructive) {
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
                Text("This will replace your current local data with data from iCloud. Your current data will be overwritten. Are you sure?")
            }
            .alert("Restore Successful", isPresented: $showingRestoreSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your data has been successfully restored from iCloud.")
            }
            .alert("Restore Failed", isPresented: $showingRestoreError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncService.syncError ?? "Failed to restore data from iCloud. Please try again.")
            }
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
