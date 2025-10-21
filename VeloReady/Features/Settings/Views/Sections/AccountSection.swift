import SwiftUI

/// Account section for sign out and data management
struct AccountSection: View {
    @Binding var showingDeleteDataAlert: Bool
    
    var body: some View {
        Section {
            // Sign out from Intervals.icu
            if IntervalsOAuthManager.shared.isAuthenticated {
                Button(action: {
                    Task {
                        await IntervalsOAuthManager.shared.signOut()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                            Text(SettingsContent.Account.signOut)
                                .foregroundColor(ColorPalette.labelPrimary)
                            Text(SettingsContent.Account.signOutSubtitle)
                                .font(TypeScale.font(size: TypeScale.xs))
                                .foregroundColor(ColorPalette.labelSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Delete all local data
            Button(role: .destructive, action: {
                // Show confirmation alert
                showingDeleteDataAlert = true
            }) {
                HStack {
                    Text(SettingsContent.Account.deleteData)
                    
                    Spacer()
                }
            }
        } header: {
            Text(SettingsContent.accountSection)
        } footer: {
            Text(SettingsContent.Account.deleteDataFooter)
        }
    }
}

// MARK: - Preview

struct AccountSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AccountSection(showingDeleteDataAlert: .constant(false))
        }
        .previewLayout(.sizeThatFits)
    }
}
