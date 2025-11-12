import SwiftUI

/// Settings view for managing data source connections
struct DataSourcesSettingsView: View {
    @StateObject private var dataSourceManager = DataSourceManager.shared
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @ObservedObject private var stravaAuthService = StravaAuthService.shared
    @State private var showingConnectionError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingIntervalsLogin = false
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = "checkmark.circle.fill"
    @State private var toastColor = ColorScale.greenAccent
    
    var body: some View {
        List {
            // Overview Section
            overviewSection
            
            // Available Sources
            ForEach(DataSource.allCases) { source in
                dataSourceRow(source)
            }
            
            // Priority Section
            prioritySection
        }
        .navigationTitle(SettingsContent.DataSources.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(CommonContent.Errors.connectionError, isPresented: $showingConnectionError) {
            Button(CommonContent.Actions.ok, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay(
            Group {
                if showingToast {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage, icon: toastIcon, color: toastColor)
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showingToast)
                }
            }
        )
        .onChange(of: stravaAuthService.connectionState) { oldState, newState in
            handleStravaStateChange(oldState: oldState, newState: newState)
        }
        .sheet(isPresented: $showingIntervalsLogin) {
            IntervalsLoginView {
                showingIntervalsLogin = false
                dataSourceManager.updateConnectionStatuses()
                
                // Trigger a data refresh across the app
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .refreshDataAfterIntervalsConnection, object: nil)
                    Logger.debug("🔄 Posted notification to refresh data after Intervals.icu connection")
                }
            }
        }
        .onAppear {
            dataSourceManager.updateConnectionStatuses()
        }
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: Icons.System.linkCircleFill)
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(CommonContent.States.connectedSources)
                            .font(.headline)
                        
                        Text(dataSourceManager.connectedSourcesSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !dataSourceManager.hasActivitySource {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: Icons.Status.warningFill)
                            .foregroundColor(.orange)
                        Text(SettingsContent.DataSources.connectWarning)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text(SettingsContent.DataSources.overview)
        }
    }
    
    // MARK: - Data Source Row
    
    private func dataSourceRow(_ source: DataSource) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Description
                Text(source.sourceDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Connection status
                HStack {
                    Text(SettingsContent.DataSources.status)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(connectionStatus(for: source))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(connectionStatusColor(for: source))
                    
                    Spacer()
                }
                
                // Branded connect button
                brandedConnectionButton(for: source)
                
                // Data types provided
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(SettingsContent.DataSources.provides)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: Spacing.sm) {
                        ForEach(source.providedDataTypes, id: \.self) { dataType in
                            Text(dataType.rawValue.capitalized)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text(source.displayName)
        }
    }
    
    // MARK: - Priority Section
    
    private var prioritySection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(SettingsContent.DataSources.dataPriority)
                    .font(.headline)
                
                Text(SettingsContent.DataSources.priorityDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(Array(dataSourceManager.sourcePriority.enumerated()), id: \.element) { index, source in
                    HStack {
                        Text("\(index + 1).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        
                        Image(systemName: source.icon)
                            .foregroundColor(source.color)
                            .frame(width: 24)
                        
                        Text(source.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Image(systemName: Icons.Navigation.menu)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text(SettingsContent.DataSources.priorityOrder)
        } footer: {
            Text(SettingsContent.DataSources.priorityFooter)
                .font(.caption)
        }
    }
    
    // MARK: - Helper Views
    
    private func brandedConnectionButton(for source: DataSource) -> some View {
        let status = dataSourceManager.connectionStatuses[source] ?? .notConnected
        let isConnected = status.isConnected
        
        return Group {
            switch source {
            case .intervalsICU:
                ConnectWithIntervalsButton(
                    action: {
                        if !isConnected {
                            // Show login sheet
                            showingIntervalsLogin = true
                        } else {
                            // Disconnect and sign out
                            Task {
                                await oauthManager.signOut()
                                dataSourceManager.disconnect(from: source)
                                dataSourceManager.updateConnectionStatuses()
                                
                                // Trigger a data refresh to switch to HealthKit-only mode
                                await MainActor.run {
                                    NotificationCenter.default.post(name: .refreshDataAfterIntervalsConnection, object: nil)
                                    Logger.debug("🔄 Posted notification to refresh data after Intervals.icu disconnection")
                                }
                            }
                        }
                    },
                    isConnected: isConnected
                )
                
            case .strava:
                VStack(spacing: 8) {
                    ConnectWithStravaButton(
                        action: {
                            if !stravaAuthService.connectionState.isConnected {
                                // Start the OAuth flow
                                stravaAuthService.startAuth()
                            } else {
                                // Disconnect
                                stravaAuthService.disconnect()
                                dataSourceManager.disconnect(from: source)
                                dataSourceManager.updateConnectionStatuses()
                            }
                        },
                        isConnected: stravaAuthService.connectionState.isConnected,
                        connectionState: stravaAuthService.connectionState
                    )
                    
                    // Show re-authenticate button if connected but no Supabase session
                    // This catches: no session OR expired/invalid tokens
                    if stravaAuthService.connectionState.isConnected && !SupabaseClient.shared.isAuthenticated {
                        let _ = print("🔍 [Settings] Showing re-auth button - Strava connected: true, Supabase authenticated: false")
                        
                        Button(action: {
                            Task {
                                await stravaAuthService.reAuthenticate()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Re-authenticate for Full Access")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                            .padding(.vertical, 8)
                        }
                    }
                }
                
            case .appleHealth, .wahoo:
                // Generic button for Apple Health and Wahoo
                Button(action: {
                    if !isConnected {
                        Task {
                            do {
                                try await dataSourceManager.connect(to: source)
                            } catch {
                                errorMessage = error.localizedDescription
                                showingConnectionError = true
                            }
                        }
                    } else {
                        dataSourceManager.disconnect(from: source)
                    }
                }) {
                    Text(isConnected ? CommonContent.Actions.disconnect : CommonContent.Actions.connect)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isConnected ? Color.red : source.color)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func connectionButton(for source: DataSource) -> some View {
        Group {
            let status = dataSourceManager.connectionStatuses[source] ?? .notConnected
            
            switch status {
            case .connected:
                Button(action: {
                    dataSourceManager.disconnect(from: source)
                }) {
                    Text(CommonContent.Actions.disconnect)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
            case .connecting:
                ProgressView()
                    .scaleEffect(0.8)
                
            case .notConnected, .error:
                Button(action: {
                    Task {
                        do {
                            try await dataSourceManager.connect(to: source)
                        } catch {
                            errorMessage = error.localizedDescription
                            showingConnectionError = true
                        }
                    }
                }) {
                    Text(SettingsContent.DataSources.connect)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func connectionStatus(for source: DataSource) -> String {
        dataSourceManager.connectionStatuses[source]?.displayText ?? "Unknown"
    }
    
    private func connectionStatusColor(for source: DataSource) -> Color {
        let status = dataSourceManager.connectionStatuses[source] ?? .notConnected
        switch status {
        case .connected: return .green
        case .connecting: return .orange
        case .notConnected: return .secondary
        case .error: return .red
        }
    }
    
    private func handleStravaStateChange(oldState: StravaConnectionState, newState: StravaConnectionState) {
        // Only show toasts for meaningful state changes (not internal loading states)
        switch (oldState, newState) {
        case (_, .connected):
            // Successfully connected
            showToast(
                message: "Connected to Strava ✓",
                icon: "checkmark.circle.fill",
                color: .green
            )
            // Trigger haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        case (.connecting, .disconnected), (.pending, .disconnected):
            // User cancelled
            showToast(
                message: "Connection cancelled",
                icon: "xmark.circle.fill",
                color: .orange
            )
            
        case (.connected, .disconnected):
            // Disconnected
            showToast(
                message: "Disconnected from Strava",
                icon: "link.badge.xmark",
                color: .secondary
            )
            
        case (_, .error(let message)):
            // Error occurred
            showToast(
                message: message,
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
            // Trigger haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
        default:
            // Don't show toast for other transitions (connecting -> pending, etc.)
            break
        }
    }
    
    private func showToast(message: String, icon: String, color: Color) {
        toastMessage = message
        toastIcon = icon
        toastColor = color
        
        withAnimation {
            showingToast = true
        }
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showingToast = false
            }
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(color)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Preview

struct DataSourcesSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DataSourcesSettingsView()
        }
    }
}
