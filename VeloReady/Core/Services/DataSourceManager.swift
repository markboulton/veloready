import Foundation
import Combine

/// Centralized manager for all data sources
/// Handles connection status, priority, and data aggregation
@MainActor
class DataSourceManager: ObservableObject {
    static let shared = DataSourceManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var connectionStatuses: [DataSource: ConnectionStatus] = [:]
    @Published var enabledSources: Set<DataSource> = []
    @Published var sourcePriority: [DataSource] = []
    
    // MARK: - Individual Source Managers
    
    private let intervalsManager = IntervalsOAuthManager.shared
    private let healthKitManager = HealthKitManager.shared
    private let stravaAuthService = StravaAuthService.shared
    
    // MARK: - Initialization
    
    private init() {
        loadSavedConfiguration()
        setupObservers()
        updateConnectionStatuses()
    }
    
    // MARK: - Configuration
    
    /// Load saved source preferences
    private func loadSavedConfiguration() {
        // Load enabled sources
        if let savedSources = UserDefaults.standard.array(forKey: "enabledDataSources") as? [String] {
            enabledSources = Set(savedSources.compactMap { DataSource(rawValue: $0) })
        } else {
            // Default: enable Intervals.icu and Apple Health
            enabledSources = [.intervalsICU, .appleHealth]
        }
        
        // Load source priority
        if let savedPriority = UserDefaults.standard.array(forKey: "dataSourcePriority") as? [String] {
            sourcePriority = savedPriority.compactMap { DataSource(rawValue: $0) }
        } else {
            // Default priority: Intervals.icu > Strava > Apple Health
            sourcePriority = [.intervalsICU, .strava, .appleHealth]
        }
    }
    
    /// Save source preferences
    private func saveConfiguration() {
        UserDefaults.standard.set(enabledSources.map { $0.rawValue }, forKey: "enabledDataSources")
        UserDefaults.standard.set(sourcePriority.map { $0.rawValue }, forKey: "dataSourcePriority")
    }
    
    // MARK: - Source Management
    
    /// Enable a data source
    func enableSource(_ source: DataSource) {
        enabledSources.insert(source)
        saveConfiguration()
        Logger.data("DataSourceManager: Enabled \(source.displayName)")
    }
    
    /// Disable a data source
    func disableSource(_ source: DataSource) {
        enabledSources.remove(source)
        saveConfiguration()
        Logger.data("DataSourceManager: Disabled \(source.displayName)")
    }
    
    /// Update source priority (for conflict resolution)
    func updatePriority(_ newPriority: [DataSource]) {
        sourcePriority = newPriority
        saveConfiguration()
        Logger.data("DataSourceManager: Updated priority: \(newPriority.map { $0.displayName })")
    }
    
    // MARK: - Connection Status
    
    /// Setup observers for connection status changes
    private func setupObservers() {
        // Observe Intervals.icu connection
        intervalsManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                self?.connectionStatuses[.intervalsICU] = isAuthenticated ? .connected : .notConnected
            }
            .store(in: &cancellables)
        
        // Observe Apple Health authorization
        healthKitManager.$isAuthorized
            .sink { [weak self] isAuthorized in
                self?.connectionStatuses[.appleHealth] = isAuthorized ? .connected : .notConnected
            }
            .store(in: &cancellables)
        
        // Observe Strava connection
        stravaAuthService.$connectionState
            .sink { [weak self] state in
                switch state {
                case .connected:
                    self?.connectionStatuses[.strava] = .connected
                case .connecting:
                    self?.connectionStatuses[.strava] = .connecting
                case .error(let message):
                    self?.connectionStatuses[.strava] = .error(message)
                default:
                    self?.connectionStatuses[.strava] = .notConnected
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Update all connection statuses
    func updateConnectionStatuses() {
        // Intervals.icu
        connectionStatuses[.intervalsICU] = intervalsManager.isAuthenticated ? .connected : .notConnected
        
        // Apple Health
        connectionStatuses[.appleHealth] = healthKitManager.isAuthorized ? .connected : .notConnected
        
        // Strava
        #if DEBUG
        Logger.debug("🔍 [DataSourceManager] Checking Strava state: \(stravaAuthService.connectionState)")
        #endif
        switch stravaAuthService.connectionState {
        case .connected:
            connectionStatuses[.strava] = .connected
        case .connecting:
            connectionStatuses[.strava] = .connecting
        case .error(let message):
            connectionStatuses[.strava] = .error(message)
        default:
            connectionStatuses[.strava] = .notConnected
        }
        
        // Garmin removed - not implemented
        
        Logger.data("DataSourceManager: Updated connection statuses")
        connectionStatuses.forEach { source, status in
            Logger.debug("   \(source.displayName): \(status.displayText)")
        }
    }
    
    // MARK: - Connection Actions
    
    /// Connect to a data source
    func connect(to source: DataSource) async throws {
        connectionStatuses[source] = .connecting
        
        switch source {
        case .intervalsICU:
            // Connection handled by IntervalsOAuthManager
            // User needs to authenticate via the login view
            Logger.data("DataSourceManager: Intervals.icu requires OAuth flow")
            
        case .appleHealth:
            // Request HealthKit authorization
            await healthKitManager.requestAuthorization()
            
        case .strava:
            // Connection handled by StravaAuthService
            stravaAuthService.startAuth()
            
        // Garmin case removed - not implemented
        }
        
        updateConnectionStatuses()
    }
    
    /// Disconnect from a data source
    func disconnect(from source: DataSource) {
        switch source {
        case .intervalsICU:
            Task { @MainActor in
                await intervalsManager.signOut()
            }
            
        case .appleHealth:
            // Cannot programmatically revoke HealthKit - user must do it in Settings
            Logger.data("DataSourceManager: Apple Health permissions must be revoked in Settings app")
            
        case .strava:
            // Disconnect from Strava
            stravaAuthService.disconnect()
            
        // Garmin case removed - not implemented
        }
        
        disableSource(source)
        updateConnectionStatuses()
    }
    
    // MARK: - Data Priority Resolution
    
    /// Get the primary source for a specific data type
    func primarySource(for dataType: DataType) -> DataSource? {
        // Return the highest priority enabled source that provides this data type
        return sourcePriority.first { source in
            enabledSources.contains(source) &&
            source.providedDataTypes.contains(dataType) &&
            connectionStatuses[source]?.isConnected == true
        }
    }
    
    /// Get all connected sources that provide a specific data type
    func connectedSources(for dataType: DataType) -> [DataSource] {
        return DataSource.allCases.filter { source in
            enabledSources.contains(source) &&
            source.providedDataTypes.contains(dataType) &&
            connectionStatuses[source]?.isConnected == true
        }
    }
    
    // MARK: - Status Queries
    
    /// Check if any activity source is connected
    var hasActivitySource: Bool {
        !connectedSources(for: .activities).isEmpty || !connectedSources(for: .workouts).isEmpty
    }
    
    /// Check if any wellness source is connected
    var hasWellnessSource: Bool {
        !connectedSources(for: .wellness).isEmpty
    }
    
    /// Get a user-friendly summary of connected sources
    var connectedSourcesSummary: String {
        let connected = DataSource.allCases.filter { connectionStatuses[$0]?.isConnected == true }
        if connected.isEmpty {
            return "No data sources connected"
        }
        return connected.map { $0.displayName }.joined(separator: ", ")
    }
}

// MARK: - Errors

enum DataSourceError: LocalizedError {
    case notImplemented
    case connectionFailed(String)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This data source is not yet implemented"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .unauthorized:
            return "Not authorized to access this data source"
        }
    }
}

