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
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sign Out from Intervals.icu")
                                .foregroundColor(.primary)
                            Text("Disconnect your account and remove access")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Delete All Local Data")
                    
                    Spacer()
                }
            }
        } header: {
            Text("Account")
        } footer: {
            Text("Delete all cached activities, metrics, and scores from this device. Your data on connected services will not be affected.")
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
