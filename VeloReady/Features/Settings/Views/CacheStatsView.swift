import SwiftUI

/// Developer view for monitoring cache performance
struct CacheStatsView: View {
    private let cacheManager = UnifiedCacheManager.shared
    @State private var performanceStats: [PerformanceStats] = []
    @State private var cacheStats: CacheStatistics?
    @State private var showingClearAlert = false
    
    var body: some View {
        List {
            // Unified Cache Section
            Section {
                if let stats = cacheStats {
                    StatRow(label: SettingsContent.Cache.hitRate, value: hitRateText, valueColor: hitRateColor)
                    StatRow(label: SettingsContent.Cache.cacheHits, value: "\(stats.hits)")
                    StatRow(label: SettingsContent.Cache.cacheMisses, value: "\(stats.misses)")
                    StatRow(label: SettingsContent.Cache.deduplicated, value: "\(stats.deduplicatedRequests)")
                } else {
                    ProgressView()
                }
            } header: {
                HStack {
                    Text(SettingsContent.Cache.itemsCached)
                    Spacer()
                    Image(systemName: Icons.System.trophy)
                        .foregroundColor(hitRateColor)
                }
            } footer: {
                Text(SettingsContent.Cache.targetHitRate)
                    .font(.caption)
            }
            
            // Stream Cache Section
            Section(SettingsContent.Cache.streamCache) {
                let streamStats = StreamCacheService.shared.getCacheStats()
                
                StatRow(label: SettingsContent.Cache.totalActivities, value: "\(streamStats.totalEntries)")
                StatRow(label: SettingsContent.Cache.totalSamples, value: formatNumber(streamStats.totalSamples))
                StatRow(label: SettingsContent.Cache.cacheHits, value: "\(streamStats.cacheHits)")
                StatRow(label: SettingsContent.Cache.cacheMisses, value: "\(streamStats.cacheMisses)")
                StatRow(label: SettingsContent.Cache.hitRate, value: "\(Int(streamStats.hitRate * 100))%")
            }
            
            // Performance Monitoring Section
            if !performanceStats.isEmpty {
                Section(SettingsContent.Cache.performanceMetrics) {
                    ForEach(performanceStats) { stat in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(SettingsContent.Cache.totalSize)
                                .font(.headline)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(SettingsContent.Cache.avgLabel): \(stat.averageMs)\(SettingsContent.Cache.msUnit)")
                                    Text("\(SettingsContent.Cache.p95Label): \(stat.p95Ms)\(SettingsContent.Cache.msUnit)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("\(SettingsContent.Cache.countLabel): \(stat.count)")
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
            Section(SettingsContent.Cache.memory) {
                StatRow(label: SettingsContent.Cache.appMemory, value: formatMemory(getAppMemory()))
                StatRow(label: SettingsContent.Cache.cacheLimit, value: SettingsContent.Cache.cacheLimitValue)
                StatRow(label: SettingsContent.Cache.cacheEntries, value: SettingsContent.Cache.cacheEntriesValue)
            }
            
            // Actions
            Section {
                Button {
                    Task {
                        await loadPerformanceStats()
                        await PerformanceMonitor.shared.printAllStatistics()
                    }
                } label: {
                    Label(SettingsContent.Cache.printStats, systemImage: "doc.text")
                }
                
                Button {
                    Task {
                        await PerformanceMonitor.shared.reset()
                        performanceStats = []
                    }
                } label: {
                    Label(SettingsContent.Cache.resetStats, systemImage: "arrow.counterclockwise")
                }
                
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Label(SettingsContent.Cache.clearAll, systemImage: "trash")
                }
            }
        }
        .navigationTitle(SettingsContent.Cache.statistics)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStats()
        }
        .refreshable {
            await loadStats()
        }
        .alert(SettingsContent.Cache.clearAll, isPresented: $showingClearAlert) {
            Button(SettingsContent.Cache.cancel, role: .cancel) {}
            Button(SettingsContent.Cache.clear, role: .destructive) {
                Task {
                    await cacheManager.invalidate(matching: "*")
                    StreamCacheService.shared.clearAllCaches()
                    Logger.debug("🗑️ All caches cleared")
                }
            }
        } message: {
            Text(SettingsContent.Cache.clearMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var hitRatePercentage: Int {
        guard let stats = cacheStats else { return 0 }
        return Int(stats.hitRate * 100)
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
    
    private func loadStats() async {
        // Load cache stats
        cacheStats = await cacheManager.getStatistics()
        
        // Load performance stats
        await loadPerformanceStats()
    }
    
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
