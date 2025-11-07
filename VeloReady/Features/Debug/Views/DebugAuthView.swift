import SwiftUI

#if DEBUG
/// Debug view for authentication and OAuth management
struct DebugAuthView: View {
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @ObservedObject private var stravaAuthService = StravaAuthService.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    
    @State private var showingIntervalsLogin = false
    
    var body: some View {
        Form {
            authStatusSection
            intervalsOAuthSection
            stravaOAuthSection
        }
        .navigationTitle("Auth")
        .sheet(isPresented: $showingIntervalsLogin) {
            IntervalsLoginView {
                showingIntervalsLogin = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .refreshDataAfterIntervalsConnection, object: nil)
                }
            }
        }
    }
    
    // MARK: - Auth Status Section
    
    private var authStatusSection: some View {
        Section {
            // HealthKit Status
            HStack(spacing: Spacing.md) {
                Image(systemName: Icons.Health.heartFill)
                    .foregroundColor(healthKitManager.isAuthorized ? ColorScale.greenAccent : ColorScale.amberAccent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("HealthKit", style: .body)
                    VRText(
                        healthKitManager.isAuthorized ? "Authorized" : "Not Authorized",
                        style: .caption,
                        color: healthKitManager.isAuthorized ? ColorScale.greenAccent : .secondary
                    )
                }
                
                Spacer()
                
                if !healthKitManager.isAuthorized {
                    Button("Authorize") {
                        Task {
                            await healthKitManager.requestAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            // Intervals.icu Status
            HStack(spacing: Spacing.md) {
                Image(systemName: Icons.Activity.cycling)
                    .foregroundColor(oauthManager.isAuthenticated ? ColorScale.greenAccent : ColorScale.amberAccent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("Intervals.icu", style: .body)
                    VRText(
                        oauthManager.isAuthenticated ? "Connected" : "Not Connected",
                        style: .caption,
                        color: oauthManager.isAuthenticated ? ColorScale.greenAccent : .secondary
                    )
                }
                
                Spacer()
                
                VRBadge(
                    oauthManager.isAuthenticated ? "Connected" : "Disconnected",
                    style: oauthManager.isAuthenticated ? .success : .warning
                )
            }
            
            if oauthManager.isAuthenticated, let user = oauthManager.user {
                HStack {
                    VRText("Athlete:", style: .caption, color: .secondary)
                    Spacer()
                    VRText(user.name, style: .caption)
                        .fontWeight(.medium)
                }
            }
            
            // Strava Status
            HStack(spacing: Spacing.md) {
                Image(systemName: Icons.DataSource.strava)
                    .foregroundColor(stravaAuthService.connectionState.isConnected ? ColorScale.greenAccent : ColorScale.amberAccent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("Strava", style: .body)
                    VRText(
                        stravaStateDescription,
                        style: .caption,
                        color: stravaAuthService.connectionState.isConnected ? ColorScale.greenAccent : .secondary
                    )
                }
                
                Spacer()
                
                VRBadge(
                    stravaAuthService.connectionState.isConnected ? "Connected" : "Not Connected",
                    style: stravaAuthService.connectionState.isConnected ? .success : .warning
                )
            }
            
            if case .connected(let athleteId) = stravaAuthService.connectionState, let id = athleteId {
                HStack {
                    VRText("Athlete ID:", style: .caption, color: .secondary)
                    Spacer()
                    VRText(id, style: .caption)
                        .fontWeight(.medium)
                }
            }
        } header: {
            Label("Authentication Status", systemImage: Icons.System.shield)
        }
    }
    
    // MARK: - Intervals OAuth Section
    
    private var intervalsOAuthSection: some View {
        Section {
            VRText("Intervals.icu", style: .headline)
            
            if oauthManager.isAuthenticated {
                Button(action: {
                    Task {
                        await oauthManager.signOut()
                        await MainActor.run {
                            NotificationCenter.default.post(name: .refreshDataAfterIntervalsConnection, object: nil)
                        }
                    }
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Arrow.rectanglePortrait)
                        VRText("Sign Out from Intervals.icu", style: .body, color: ColorScale.redAccent)
                    }
                }
                
                HStack {
                    VRText("Status:", style: .body, color: .secondary)
                    Spacer()
                    VRBadge("Connected", style: .success)
                }
            } else {
                HStack {
                    VRText("Status:", style: .body, color: .secondary)
                    Spacer()
                    VRBadge("Disconnected", style: .warning)
                }
                
                Button(action: {
                    showingIntervalsLogin = true
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Arrow.rightCircleFill)
                        VRText("Connect to Intervals.icu", style: .body)
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if let accessToken = oauthManager.accessToken {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("Access Token", style: .caption, color: .secondary)
                    Text("\(String(accessToken.prefix(20)))...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label("Intervals.icu OAuth", systemImage: Icons.Activity.cycling)
        }
    }
    
    // MARK: - Strava OAuth Section
    
    private var stravaOAuthSection: some View {
        Section {
            VRText("Strava", style: .headline)
            
            if stravaAuthService.connectionState.isConnected {
                Button(action: {
                    stravaAuthService.disconnect()
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Arrow.rectanglePortrait)
                        VRText("Sign Out from Strava", style: .body, color: ColorScale.redAccent)
                    }
                }
                
                HStack {
                    VRText("Status:", style: .body, color: .secondary)
                    Spacer()
                    VRBadge("Connected", style: .success)
                }
                
                if case .connected(let athleteId) = stravaAuthService.connectionState, let id = athleteId {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        VRText("Athlete ID", style: .caption, color: .secondary)
                        Text(id)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    VRText("Status:", style: .body, color: .secondary)
                    Spacer()
                    VRBadge(
                        stravaStateDescription,
                        style: stravaAuthService.connectionState.isLoading ? .warning : .neutral
                    )
                }
                
                Button(action: {
                    stravaAuthService.startAuth()
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Arrow.rightCircleFill)
                        VRText("Connect to Strava", style: .body)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(stravaAuthService.connectionState.isLoading)
                
                if case .error(let message) = stravaAuthService.connectionState {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        VRText("Error", style: .caption, color: ColorScale.redAccent)
                        VRText(message, style: .caption, color: .secondary)
                    }
                }
            }
        } header: {
            Label("Strava OAuth", systemImage: Icons.DataSource.strava)
        } footer: {
            VRText(
                "Manage OAuth connections to Intervals.icu and Strava. Sign out to test HealthKit-only mode.",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - Helper
    
    private var stravaStateDescription: String {
        switch stravaAuthService.connectionState {
        case .disconnected: return "Not Connected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error: return "Error"
        @unknown default: return "Unknown"
        }
    }
}

#Preview {
    NavigationStack {
        DebugAuthView()
    }
}
#endif
