import SwiftUI

/// Developer view for monitoring cache performance
struct CacheStatsView: View {
    @StateObject private var cacheManager = UnifiedCacheManager.shared
    @State private var performanceStats: [PerformanceStats] = []
    @State private var showingClearAlert = false
    
    var body: some View {
        List {
            // Unified Cache Section
            Section {
                StatRow(label: SettingsContent.Cache.hitRate, value: hitRateText, valueColor: hitRateColor)
                StatRow(label: SettingsContent.Cache.cacheHits, value: "\(cacheManager.cacheHits)")
                StatRow(label: SettingsContent.Cache.cacheMisses, value: "\(cacheManager.cacheMisses)")
                StatRow(label: SettingsContent.Cache.deduplicated, value: "\(cacheManager.deduplicatedRequests)")
            } header: {
                HStack {
                    Text(SettingsContent.Cache.itemsCached)
                    Spacer()
                    Image(systemName: "trophy.fill")
                        .foregroundColor(hitRateColor)
                }
            } footer: {
                Text(SettingsContent.Cache.targetHitRate)
                    .font(.caption)
            }
            
            // Stream Cache Section
            Section("Stream Cache") {
                let streamStats = StreamCacheService.shared.getCacheStats()
                
                StatRow(label: "Total Activities", value: "\(streamStats.totalEntries)")
                StatRow(label: "Total Samples", value: formatNumber(streamStats.totalSamples))
                StatRow(label: "Cache Hits", value: "\(streamStats.cacheHits)")
                StatRow(label: "Cache Misses", value: "\(streamStats.cacheMisses)")
                StatRow(label: "Hit Rate", value: "\(Int(streamStats.hitRate * 100))%")
            }
            
            // Performance Monitoring Section
            if !performanceStats.isEmpty {
                Section("Performance Metrics") {
                    ForEach(performanceStats) { stat in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(SettingsContent.Cache.totalSize)
                                .font(.headline)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Avg: \(stat.averageMs)ms")
                                    Text("P95: \(stat.p95Ms)ms")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Count: \(stat.count)")
                                    Text(SettingsContent.Cache.statistics)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Memory Info
            Section("Memory") {
                StatRow(label: "App Memory", value: formatMemory(getAppMemory()))
                StatRow(label: "Cache Limit", value: "50 MB")
                StatRow(label: "Cache Entries", value: "200 max")
            }
            
            // Actions
            Section {
                Button {
                    Task {
                        await loadPerformanceStats()
                        await PerformanceMonitor.shared.printAllStatistics()
                    }
                } label: {
                    Label("Print Stats to Console", systemImage: "doc.text")
                }
                
                Button {
                    Task {
                        await PerformanceMonitor.shared.reset()
                        performanceStats = []
                    }
                } label: {
                    Label(SettingsContent.Cache.statistics, systemImage: "arrow.counterclockwise")
                }
                
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Label(SettingsContent.Cache.clearAll, systemImage: "trash")
                }
            }
        }
        .navigationTitle("Cache Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPerformanceStats()
        }
        .refreshable {
            await loadPerformanceStats()
        }
        .alert(SettingsContent.Cache.clearAll, isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                cacheManager.invalidate(matching: "*")
                StreamCacheService.shared.clearAllCaches()
                Logger.debug("🗑️ All caches cleared")
            }
        } message: {
            Text("This will clear all cached data. The app will re-fetch data as needed.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var hitRatePercentage: Int {
        let total = cacheManager.cacheHits + cacheManager.cacheMisses
        guard total > 0 else { return 0 }
        return Int(Double(cacheManager.cacheHits) / Double(total) * 100)
    }
    
    private var hitRateText: String {
        "\(hitRatePercentage)%"
    }
    
    private var hitRateColor: Color {
        let rate = hitRatePercentage
        if rate >= 85 { return .green }
        if rate >= 70 { return .orange }
        return .red
    }
    
    // MARK: - Helpers
    
    private func loadPerformanceStats() async {
        let labels = await PerformanceMonitor.shared.getAllLabels()
        var stats: [PerformanceStats] = []
        
        for label in labels {
            if let stat = await PerformanceMonitor.shared.getStatistics(for: label) {
                stats.append(stat)
            }
        }
        
        performanceStats = stats.sorted { $0.count > $1.count }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func formatMemory(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.1f MB", mb)
    }
    
    private func getAppMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }
}

#Preview {
    NavigationStack {
        CacheStatsView()
    }
}
