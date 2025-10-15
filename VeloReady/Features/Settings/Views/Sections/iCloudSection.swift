import SwiftUI

/// iCloud sync section for settings
struct iCloudSection: View {
    @StateObject private var syncService = iCloudSyncService.shared
    @State private var showingCloudSettings = false
    
    var body: some View {
        Section {
            Button(action: {
                showingCloudSettings = true
            }) {
                HStack {
                    Image(systemName: "icloud.fill")
                        .foregroundColor(Color.button.primary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud Sync")
                            .foregroundColor(.primary)
                        
                        if syncService.isCloudAvailable {
                            if let lastSync = syncService.lastSyncDate {
                                Text("Last synced \(lastSync, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Ready to sync")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Not available")
                                .font(.caption)
                                .foregroundColor(Color.semantic.warning)
                        }
                    }
                    
                    Spacer()
                    
                    if syncService.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Data & Sync")
        } footer: {
            Text("Automatically sync your settings, workout data, and strength exercise logs to iCloud.")
        }
        .sheet(isPresented: $showingCloudSettings) {
            iCloudSettingsView()
        }
    }
}

// MARK: - Preview

struct iCloudSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            iCloudSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
