import Foundation
import SwiftUI

/// Monitor and log rate limit usage across all providers
/// Provides real-time status and historical tracking
@MainActor
class RateLimitMonitor: ObservableObject {
    // MARK: - Singleton
    static let shared = RateLimitMonitor()
    
    // MARK: - Published State
    @Published var providerStatus: [DataSource: ProviderRateLimitStatus] = [:]
    @Published var recentViolations: [RateLimitViolation] = []
    @Published var aggregateStats: AggregateRateLimitStats = AggregateRateLimitStats()
    
    // MARK: - Configuration
    private let maxViolationsToTrack = 50
    private let monitoringEnabled = true
    
    // MARK: - Initialization
    private init() {
        // Initialize status for all providers
        updateAllProviderStatus()
    }
    
    // MARK: - Public Methods
    
    /// Update status for all configured providers
    func updateAllProviderStatus() {
        Task {
            for provider in [DataSource.strava, DataSource.intervalsICU, DataSource.appleHealth] {
                let status = await RequestThrottler.shared.getProviderStatus(provider: provider)
                providerStatus[provider] = status
            }
        }
    }
    
    /// Log a rate limit violation
    func logViolation(
        provider: DataSource,
        endpoint: String?,
        retryAfter: TimeInterval,
        reason: String?
    ) {
        guard monitoringEnabled else { return }
        
        let violation = RateLimitViolation(
            provider: provider,
            endpoint: endpoint,
            retryAfter: retryAfter,
            reason: reason,
            timestamp: Date()
        )
        
        // Add to violations list (keep max 50)
        recentViolations.insert(violation, at: 0)
        if recentViolations.count > maxViolationsToTrack {
            recentViolations.removeLast()
        }
        
        // Update aggregate stats
        aggregateStats.recordViolation(provider: provider)
        
        // Log to console
        Logger.warning("⚠️ [RateLimitMonitor] Violation: \(violation.displayString)")
        
        // Update provider status
        updateAllProviderStatus()
    }
    
    /// Log a successful request
    func logSuccessfulRequest(provider: DataSource, endpoint: String?) {
        guard monitoringEnabled else { return }
        
        // Update aggregate stats
        aggregateStats.recordSuccess(provider: provider)
        
        // Periodically update status (every 10th request to avoid overhead)
        if aggregateStats.totalRequests(for: provider) % 10 == 0 {
            updateAllProviderStatus()
        }
    }
    
    /// Get health score for a provider (0-100)
    /// Based on violation rate and remaining capacity
    func getHealthScore(for provider: DataSource) -> Double {
        guard let status = providerStatus[provider] else { return 100.0 }
        
        let stats = aggregateStats.providerStats[provider]
        let successCount = stats?.successCount ?? 0
        let violationCount = stats?.violationCount ?? 0
        let totalRequests = Double(successCount + violationCount)
        let violations = Double(violationCount)
        
        // Calculate violation rate (0-1)
        let violationRate = totalRequests > 0 ? violations / totalRequests : 0.0
        
        // Calculate remaining capacity (0-1)
        var avgRemaining = 0.0
        var count = 0
        
        if let remaining15 = status.remaining15Min, let max15 = status.max15Min {
            avgRemaining += Double(remaining15) / Double(max15)
            count += 1
        }
        if let remainingHour = status.remainingHour, let maxHour = status.maxHour {
            avgRemaining += Double(remainingHour) / Double(maxHour)
            count += 1
        }
        if let remainingDay = status.remainingDay, let maxDay = status.maxDay {
            avgRemaining += Double(remainingDay) / Double(maxDay)
            count += 1
        }
        
        if count > 0 {
            avgRemaining /= Double(count)
        } else {
            avgRemaining = 1.0 // No limits = perfect score
        }
        
        // Weight: 60% capacity, 40% violation rate
        let healthScore = (avgRemaining * 0.6 + (1.0 - violationRate) * 0.4) * 100.0
        
        return max(0, min(100, healthScore))
    }
    
    /// Export monitoring data for debugging
    func exportDiagnostics() -> String {
        var output = "=== Rate Limit Diagnostics ===\n\n"
        
        // Provider Status
        output += "## Provider Status\n"
        for (provider, status) in providerStatus.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            output += "- \(provider.rawValue):\n"
            output += "  \(status.displayString)\n"
            output += "  Health Score: \(String(format: "%.1f", getHealthScore(for: provider)))%\n"
        }
        output += "\n"
        
        // Aggregate Stats
        output += "## Aggregate Stats\n"
        for (provider, stats) in aggregateStats.providerStats.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            output += "- \(provider.rawValue):\n"
            output += "  Successful: \(stats.successCount)\n"
            output += "  Violations: \(stats.violationCount)\n"
            let violationRate = stats.successCount + stats.violationCount > 0 ?
                Double(stats.violationCount) / Double(stats.successCount + stats.violationCount) * 100.0 : 0.0
            output += "  Violation Rate: \(String(format: "%.2f", violationRate))%\n"
        }
        output += "\n"
        
        // Recent Violations
        output += "## Recent Violations (\(min(recentViolations.count, 10)) most recent)\n"
        for violation in recentViolations.prefix(10) {
            output += "- [\(formatTimestamp(violation.timestamp))] \(violation.displayString)\n"
        }
        
        return output
    }
    
    // MARK: - Private Methods
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Models

struct RateLimitViolation: Identifiable {
    let id = UUID()
    let provider: DataSource
    let endpoint: String?
    let retryAfter: TimeInterval
    let reason: String?
    let timestamp: Date
    
    var displayString: String {
        var parts: [String] = []
        parts.append(provider.rawValue)
        if let endpoint = endpoint {
            parts.append("(\(endpoint))")
        }
        if let reason = reason {
            parts.append(reason)
        }
        parts.append("retry in \(Int(retryAfter))s")
        return parts.joined(separator: " ")
    }
}

struct ProviderStats: Codable {
    var successCount: Int = 0
    var violationCount: Int = 0
}

struct AggregateRateLimitStats: Codable {
    var providerStats: [DataSource: ProviderStats] = [:]
    
    mutating func recordSuccess(provider: DataSource) {
        if providerStats[provider] == nil {
            providerStats[provider] = ProviderStats()
        }
        providerStats[provider]?.successCount += 1
    }
    
    mutating func recordViolation(provider: DataSource) {
        if providerStats[provider] == nil {
            providerStats[provider] = ProviderStats()
        }
        providerStats[provider]?.violationCount += 1
    }
    
    func totalRequests(for provider: DataSource) -> Int {
        guard let stats = providerStats[provider] else { return 0 }
        return stats.successCount + stats.violationCount
    }
}

// MARK: - SwiftUI View for Monitoring

struct RateLimitMonitorView: View {
    @StateObject private var monitor = RateLimitMonitor.shared
    @State private var showingDiagnostics = false
    
    var body: some View {
        List {
            Section("Provider Status") {
                ForEach(Array(monitor.providerStatus.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { provider in
                    if let status = monitor.providerStatus[provider] {
                        ProviderStatusRow(provider: provider, status: status)
                    }
                }
            }
            
            Section("Recent Violations") {
                if monitor.recentViolations.isEmpty {
                    Text("No violations recorded")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(monitor.recentViolations.prefix(10)) { violation in
                        ViolationRow(violation: violation)
                    }
                }
            }
        }
        .navigationTitle("Rate Limit Monitor")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Export") {
                    showingDiagnostics = true
                }
            }
        }
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsView(diagnostics: monitor.exportDiagnostics())
        }
        .onAppear {
            monitor.updateAllProviderStatus()
        }
    }
}

struct ProviderStatusRow: View {
    let provider: DataSource
    let status: ProviderRateLimitStatus
    
    var healthScore: Double {
        RateLimitMonitor.shared.getHealthScore(for: provider)
    }
    
    var healthColor: Color {
        if healthScore >= 80 {
            return .green
        } else if healthScore >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(provider.rawValue)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(healthColor)
                        .frame(width: 8, height: 8)
                    Text("\(Int(healthScore))%")
                        .font(.caption)
                        .foregroundColor(healthColor)
                }
            }
            
            Text(status.displayString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ViolationRow: View {
    let violation: RateLimitViolation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(violation.provider.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(violation.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let endpoint = violation.endpoint {
                Text(endpoint)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let reason = violation.reason {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 2)
    }
}

struct DiagnosticsView: View {
    let diagnostics: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(diagnostics)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Copy") {
                        UIPasteboard.general.string = diagnostics
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Rate Limit Monitor") {
    NavigationStack {
        RateLimitMonitorView()
    }
}

