import SwiftUI

/// Adaptive VO₂ Max card (50% width) with RAG-colored sparkline
struct AdaptiveVO2MaxCard: View {
    @StateObject private var viewModel = AdaptiveVO2MaxCardViewModel()
    let onTap: () -> Void
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: "Adaptive VO₂",
                subtitle: nil,
                action: .init(icon: Icons.System.chevronRight, action: onTap)
            ),
            style: .standard
        ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Primary metric - large and white
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            VRText(viewModel.vo2Value, style: .largeTitle)
                            VRText("ml/kg/min", style: .caption)
                                .foregroundColor(.secondary)
                        }
                    
                        // Secondary metric - smaller and grey
                        if let level = viewModel.fitnessLevel {
                            VRText(level, style: .body)
                                .foregroundColor(.secondary)
                        }
                    }
                
                    // RAG-colored sparkline (30-day trend)
                    if viewModel.hasData {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            RAGSparkline(
                                values: viewModel.sparklineValues,
                                color: viewModel.trendColor,
                                height: 32
                            )

                            // Trend indicator with period label
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: viewModel.trendIcon)
                                    .font(.caption2)
                                    .foregroundColor(viewModel.trendColor)
                                VRText(viewModel.trendText, style: .caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                VRText("30 days", style: .caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .opacity(viewModel.sparklineValues.isEmpty ? 0 : 1)
                        .offset(x: viewModel.sparklineValues.isEmpty ? 20 : 0)
                        .animation(.easeOut(duration: 0.4), value: viewModel.sparklineValues.count)
                    } else {
                        // Data source indicator (for non-PRO or users without sparkline data)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(spacing: Spacing.xs) {
                                if viewModel.dataSource == "Estimated" {
                                    Image(systemName: Icons.System.lock)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                VRText(viewModel.dataSource, style: .caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        .onAppear {
            Task {
                await viewModel.load()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class AdaptiveVO2MaxCardViewModel: ObservableObject {
    @Published var vo2Value: String = "—"
    @Published var fitnessLevel: String?
    @Published var sparklineValues: [Double] = []
    @Published var trendColor: Color = .secondary
    @Published var trendIcon: String = Icons.Arrow.right
    @Published var trendText: String = "No change"
    @Published var hasData: Bool = false
    @Published var dataSource: String = "Estimated" // "Estimated", "HR-based", or "Power-based"

    private let profileManager = AthleteProfileManager.shared
    private let proConfig = ProFeatureConfig.shared

    func load() async {
        let profile = profileManager.profile
        let hasPro = proConfig.hasProAccess

        Logger.debug("🏃 [VO2MaxCard] Loading card data")
        Logger.debug("   hasPro: \(hasPro)")

        // Determine data source and VO2 Max value based on three-tier system
        var vo2: Double?

        if hasPro {
            // Pro user: Check for power meter data
            do {
                let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 50, daysBack: 90)
                let hasPowerMeter = AthleteProfileManager.hasPowerMeterData(activities: activities)

                if hasPowerMeter {
                    // Tier 3: Pro with power meter - use VO2 calculated from FTP
                    vo2 = profile.vo2maxEstimate
                    dataSource = "Power-based"
                    Logger.debug("🔋 Pro user with power meter - using VO2 from FTP: \(vo2?.description ?? "nil")")
                } else {
                    // Tier 2: Pro without power meter - estimate from HR
                    if let maxHR = profile.maxHR {
                        vo2 = AthleteProfileManager.estimateVO2MaxFromHR(
                            maxHR: maxHR,
                            restingHR: profile.restingHR,
                            age: nil  // Age not available in profile
                        )
                        dataSource = "HR-based"
                        Logger.debug("❤️ Pro user without power meter - HR-based VO2: \(vo2?.description ?? "nil")")
                    } else {
                        // Fallback to Coggan default if HR data incomplete
                        vo2 = AthleteProfileManager.getCogganDefaultVO2Max(age: nil, gender: profile.sex)
                        dataSource = "Estimated"
                        Logger.debug("📊 Pro user with incomplete data - using Coggan default VO2")
                    }
                }
            } catch {
                Logger.error("Failed to fetch activities: \(error)")
                // Fallback to existing VO2 or Coggan default
                vo2 = profile.vo2maxEstimate ?? AthleteProfileManager.getCogganDefaultVO2Max(age: nil, gender: profile.sex)
                dataSource = profile.vo2maxEstimate != nil ? "Power-based" : "Estimated"
            }
        } else {
            // Tier 1: Free user - use Coggan default
            vo2 = AthleteProfileManager.getCogganDefaultVO2Max(age: nil, gender: profile.sex)
            dataSource = "Estimated"
            Logger.debug("🆓 Free user - using Coggan default VO2: \(String(format: "%.1f", vo2 ?? 0))")
        }

        // Format VO2
        if let vo2 = vo2 {
            vo2Value = String(format: "%.1f", vo2)
            fitnessLevel = classifyVO2Max(vo2)

            Logger.debug("   vo2Value set to: \(vo2Value)")
            Logger.debug("   fitnessLevel: \(fitnessLevel ?? "nil")")

            // Show sparkline for PRO users
            if hasPro {
                hasData = true

                // Load sparkline data asynchronously with 0.2s delay (staggered animation)
                Task {
                    // Delay by 0.2s to stagger animation with FTP card
                    try? await Task.sleep(nanoseconds: 200_000_000)

                    let sparkline = await profileManager.fetchHistoricalVO2Sparkline()

                    // Calculate trend from sparkline
                    if let first = sparkline.first, let last = sparkline.last, first > 0 {
                        let change = ((last - first) / first) * 100

                        await MainActor.run {
                            sparklineValues = sparkline

                            // Determine RAG color based on overall trend
                            if change > 2 {
                                trendColor = ColorScale.greenAccent
                                trendIcon = Icons.Arrow.upRight
                                trendText = "+\(Int(change))%"
                            } else if change < -2 {
                                trendColor = ColorScale.redAccent
                                trendIcon = Icons.Arrow.downRight
                                trendText = "\(Int(change))%"
                            } else if change > 0 {
                                trendColor = ColorScale.greenAccent.opacity(0.7)
                                trendIcon = Icons.Arrow.up
                                trendText = "+\(Int(change))%"
                            } else if change < 0 {
                                trendColor = ColorScale.amberAccent
                                trendIcon = Icons.Arrow.down
                                trendText = "\(Int(change))%"
                            } else {
                                trendColor = .secondary
                                trendIcon = Icons.Arrow.right
                                trendText = "Stable"
                            }
                        }
                    }
                }
            } else {
                hasData = false
                Logger.debug("   hasData: false (no PRO)")
            }
        } else {
            // No VO2 estimate available - show placeholder
            vo2Value = "—"
            fitnessLevel = "Not available"
            hasData = false
            Logger.debug("   ❌ No VO2 estimate available - showing placeholder")
        }
    }

    // Deprecated - now using cached historical data
    private func classifyVO2Max(_ vo2: Double) -> String {
        // Simplified classification (would need age/gender for accuracy)
        if vo2 >= 55 {
            return "Superior"
        } else if vo2 >= 50 {
            return "Excellent"
        } else if vo2 >= 45 {
            return "Good"
        } else if vo2 >= 40 {
            return "Fair"
        } else {
            return "Average"
        }
    }
    
    private func generateRealisticTrend(current: Double) -> (values: [Double], percentChange: Double) {
        // Generate 30-day trend with realistic ups and downs
        let days = 30
        let start = current * 0.96
        let overallGain = current - start
        
        var values: [Double] = []
        
        for day in 0..<days {
            // Add daily progression toward target
            let baseProgress = overallGain * (Double(day) / Double(days))
            
            // Add realistic noise (±1.5% daily variation)
            let noise = Double.random(in: -0.015...0.015) * current
            
            // Add weekly cycles (training/recovery)
            let weeklyVariation = sin(Double(day) / 7.0 * .pi * 2) * (current * 0.01)
            
            let value = start + baseProgress + noise + weeklyVariation
            values.append(value)
        }
        
        let percentChange = ((current - start) / start) * 100
        return (values, percentChange)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: Spacing.md) {
        AdaptiveVO2MaxCard(onTap: {})
        AdaptiveVO2MaxCard(onTap: {})
    }
    .padding()
    .background(Color.background.primary)
}
