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
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(SettingsContent.iCloud.title)
                            .foregroundColor(ColorPalette.labelPrimary)
                        
                        if syncService.isCloudAvailable {
                            if let lastSync = syncService.lastSyncDate {
                                Text("\(SettingsContent.iCloud.lastSynced) \(lastSync, style: .relative)")
                                    .font(TypeScale.font(size: TypeScale.xs))
                                    .foregroundColor(ColorPalette.labelSecondary)
                            } else {
                                Text(SettingsContent.iCloud.readyToSync)
                                    .font(TypeScale.font(size: TypeScale.xs))
                                    .foregroundColor(ColorPalette.labelSecondary)
                            }
                        } else {
                            Text(SettingsContent.iCloud.notAvailable)
                                .font(TypeScale.font(size: TypeScale.xs))
                                .foregroundColor(ColorPalette.warning)
                        }
                    }
                    
                    Spacer()
                    
                    if syncService.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(TypeScale.font(size: TypeScale.xs))
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                }
            }
        } header: {
            Text(SettingsContent.dataSyncSection)
        } footer: {
            Text(SettingsContent.iCloud.footer)
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
