import Foundation
import Network
import SwiftUI

/// Network connectivity monitor to detect offline/online state changes
/// Observes network path changes using NWPathMonitor from the Network framework
///
/// Usage:
/// ```swift
/// @StateObject private var networkMonitor = NetworkMonitor.shared
///
/// var body: some View {
///     if !networkMonitor.isConnected {
///         Text("No internet connection")
///     }
/// }
/// ```
@MainActor
class NetworkMonitor: ObservableObject {
    // MARK: - Singleton
    static let shared = NetworkMonitor()

    // MARK: - Published Properties

    /// Whether the device is currently connected to the internet
    @Published private(set) var isConnected: Bool = true

    /// The type of network connection currently active (wifi, cellular, etc.)
    @Published private(set) var connectionType: NWInterface.InterfaceType?

    // MARK: - Private Properties

    /// Network path monitor from the Network framework
    private let monitor = NWPathMonitor()

    /// Background queue for network monitoring
    private let monitorQueue = DispatchQueue(label: "com.veloready.networkmonitor", qos: .utility)

    /// Track previous connection state to detect transitions
    private var previouslyConnected: Bool = true

    // MARK: - Initialization

    private init() {
        Logger.debug("🌐 [NetworkMonitor] Initializing network monitor")
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Start monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            Task { @MainActor in
                // Update connection state
                let wasConnected = self.isConnected
                let nowConnected = path.status == .satisfied

                self.isConnected = nowConnected

                // Determine connection type
                self.connectionType = self.determineConnectionType(from: path)

                // Log state transitions
                self.logStateTransition(from: wasConnected, to: nowConnected, type: self.connectionType)

                // Track previous state
                self.previouslyConnected = nowConnected
            }
        }

        monitor.start(queue: monitorQueue)
        Logger.debug("🌐 [NetworkMonitor] Started monitoring network connectivity")
    }

    /// Stop monitoring network connectivity
    nonisolated func stopMonitoring() {
        monitor.cancel()
        Logger.debug("🌐 [NetworkMonitor] Stopped monitoring network connectivity")
    }

    // MARK: - Private Methods

    /// Determine the active connection type from available interfaces
    /// - Parameter path: The network path
    /// - Returns: The interface type (wifi, cellular, etc.)
    private func determineConnectionType(from path: NWPath) -> NWInterface.InterfaceType? {
        // Check available interfaces in priority order
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        } else if path.usesInterfaceType(.other) {
            return .other
        }
        return nil
    }

    /// Log state transitions for debugging
    /// - Parameters:
    ///   - wasConnected: Previous connection state
    ///   - nowConnected: Current connection state
    ///   - type: Current connection type
    private func logStateTransition(from wasConnected: Bool, to nowConnected: Bool, type: NWInterface.InterfaceType?) {
        // Only log on state changes
        if wasConnected != nowConnected {
            if nowConnected {
                let connectionTypeString = type?.description ?? "unknown"
                Logger.info("✅ [NetworkMonitor] Network connection restored (\(connectionTypeString))")
            } else {
                Logger.warning("⚠️ [NetworkMonitor] Network connection lost - device is offline")
            }
        }
    }

    /// Get human-readable description of connection status
    var statusDescription: String {
        if isConnected {
            let typeString = connectionType?.description ?? "unknown"
            return "Connected via \(typeString)"
        } else {
            return "Offline - No internet connection"
        }
    }

    /// Check if connection is cellular (useful for data usage warnings)
    var isUsingCellular: Bool {
        return isConnected && connectionType == .cellular
    }

    /// Check if connection is Wi-Fi (useful for large downloads)
    var isUsingWiFi: Bool {
        return isConnected && connectionType == .wifi
    }
}

// MARK: - NWInterface.InterfaceType Extension

extension NWInterface.InterfaceType {
    /// Human-readable description of interface type
    var description: String {
        switch self {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}
