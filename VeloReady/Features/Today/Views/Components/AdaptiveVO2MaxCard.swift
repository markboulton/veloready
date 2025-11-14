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
                    } else {
                        // Non-PRO fallback
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: Icons.System.lock)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                VRText("Estimated", style: .caption)
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
    
    private let profileManager = AthleteProfileManager.shared
    private let proConfig = ProFeatureConfig.shared
    
    func load() async {
        // Use estimated VO2 from profile (calculated from adaptive zones)
        let estimatedVO2 = profileManager.profile.vo2maxEstimate
        let hasPro = proConfig.hasProAccess
        
        Logger.debug("🏃 [VO2MaxCard] Loading card data")
        Logger.debug("   estimatedVO2: \(estimatedVO2?.description ?? "nil")")
        Logger.debug("   hasPro: \(hasPro)")
        
        // Format VO2
        if let vo2 = estimatedVO2 {
            vo2Value = String(format: "%.1f", vo2)
            fitnessLevel = classifyVO2Max(vo2)
            
            Logger.debug("   vo2Value set to: \(vo2Value)")
            Logger.debug("   fitnessLevel: \(fitnessLevel ?? "nil")")
            
            // Show sparkline for PRO users
            if hasPro {
                hasData = true
                
                // TODO: Fetch actual VO2 Max history from Core Data
                // For now, generate realistic mock trend with ups and downs
                let trend = generateRealisticTrend(current: vo2)
                sparklineValues = trend.values
                
                Logger.debug("   Generated \(sparklineValues.count) sparkline values")
                Logger.debug("   First 3 values: \(sparklineValues.prefix(3).map { String(format: "%.1f", $0) }.joined(separator: ", "))")
                
                // Determine RAG color based on overall trend
                let change = trend.percentChange
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
                
                Logger.debug("   hasData: true, trendText: \(trendText)")
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
