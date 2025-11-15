import SwiftUI

/// Adaptive FTP card (50% width) with RAG-colored sparkline
struct AdaptiveFTPCard: View {
    @StateObject private var viewModel = AdaptiveFTPCardViewModel()
    let onTap: () -> Void
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: "Adaptive FTP",
                subtitle: nil,
                action: .init(icon: Icons.System.chevronRight, action: onTap)
            ),
            style: .standard
        ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Primary metric - large and white
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            VRText(viewModel.ftpValue, style: .largeTitle)
                            VRText("W", style: .body)
                                .foregroundColor(.secondary)
                        }
                    
                    // Secondary metric - smaller and grey
                    if let wPerKg = viewModel.wPerKg {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            VRText(viewModel.wPerKgValue, style: .body)
                                .foregroundColor(.secondary)
                            VRText("W/kg", style: .caption)
                                .foregroundColor(.secondary)
                        }
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
class AdaptiveFTPCardViewModel: ObservableObject {
    @Published var ftpValue: String = "—"
    @Published var wPerKg: String?
    @Published var wPerKgValue: String = ""
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
        let weight = profile.weight
        let hasPro = proConfig.hasProAccess

        // Determine data source and FTP value based on three-tier system
        var ftp: Double = 0

        if hasPro {
            // Pro user: Check for power meter data
            do {
                let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 50, daysBack: 90)
                let hasPowerMeter = AthleteProfileManager.hasPowerMeterData(activities: activities)

                if hasPowerMeter {
                    // Tier 3: Pro with power meter - use adaptive FTP
                    ftp = profile.ftp ?? 0
                    dataSource = "Power-based"
                    Logger.debug("🔋 Pro user with power meter - using adaptive FTP: \(Int(ftp))W")
                } else {
                    // Tier 2: Pro without power meter - estimate from HR
                    if let maxHR = profile.maxHR,
                       let lthr = profile.lthr,
                       let weight = weight,
                       let estimatedFTP = AthleteProfileManager.estimateFTPFromHR(maxHR: maxHR, lthr: lthr, weight: weight) {
                        ftp = estimatedFTP
                        dataSource = "HR-based"
                        Logger.debug("❤️ Pro user without power meter - HR-based FTP: \(Int(ftp))W")
                    } else {
                        // Fallback to Coggan default if HR data incomplete
                        ftp = AthleteProfileManager.getCogganDefaultFTP(weight: weight)
                        dataSource = "Estimated"
                        Logger.debug("📊 Pro user with incomplete data - using Coggan default: \(Int(ftp))W")
                    }
                }
            } catch {
                Logger.error("Failed to fetch activities: \(error)")
                // Fallback to existing FTP or Coggan default
                ftp = profile.ftp ?? AthleteProfileManager.getCogganDefaultFTP(weight: weight)
                dataSource = ftp == profile.ftp ? "Power-based" : "Estimated"
            }
        } else {
            // Tier 1: Free user - use Coggan default
            ftp = AthleteProfileManager.getCogganDefaultFTP(weight: weight)
            dataSource = "Estimated"
            Logger.debug("🆓 Free user - using Coggan default FTP: \(Int(ftp))W")
        }

        // Format FTP
        if ftp > 0 {
            ftpValue = "\(Int(ftp))"

            // Calculate W/kg if weight available
            if let weight = weight, weight > 0 {
                let wPerKgVal = ftp / weight
                wPerKgValue = String(format: "%.1f", wPerKgVal)
                wPerKg = "yes" // Just a flag
            }
        } else {
            ftpValue = "—"
        }

        // Only show sparkline for PRO users with FTP data
        if hasPro, ftp > 0 {
            hasData = true

            // TODO: Fetch actual FTP history from Core Data
            // For now, generate realistic mock trend with ups and downs
            let trend = generateRealisticTrend(current: ftp)
            sparklineValues = trend.values

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
        } else {
            hasData = false
        }
    }
    
    private func generateRealisticTrend(current: Double) -> (values: [Double], percentChange: Double) {
        // Generate 30-day trend with realistic ups and downs
        let days = 30
        let start = current * 0.95
        let overallGain = current - start
        
        var values: [Double] = []
        var currentValue = start
        
        for day in 0..<days {
            // Add daily progression toward target
            let baseProgress = overallGain * (Double(day) / Double(days))
            
            // Add realistic noise (±2% daily variation)
            let noise = Double.random(in: -0.02...0.02) * current
            
            // Add weekly cycles (fatigue/recovery)
            let weeklyVariation = sin(Double(day) / 7.0 * .pi * 2) * (current * 0.015)
            
            currentValue = start + baseProgress + noise + weeklyVariation
            values.append(currentValue)
        }
        
        let percentChange = ((current - start) / start) * 100
        return (values, percentChange)
    }
}

// MARK: - RAG Sparkline Component with Gradient

struct RAGSparkline: View {
    let values: [Double]
    let color: Color
    let height: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate baseline (midpoint between min and max)
            let maxValue = values.max() ?? 1
            let minValue = values.min() ?? 0
            let baseline = (maxValue + minValue) / 2
            let range = maxValue - minValue
            
            // Create gradient based on baseline
            let gradient = LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: ColorScale.redAccent, location: 0.0),      // Below baseline
                    .init(color: ColorScale.amberAccent, location: 0.4),    // Near baseline
                    .init(color: ColorScale.greenAccent, location: 1.0)     // Above baseline
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            
            Path { path in
                guard !values.isEmpty else { return }
                
                let stepX = geometry.size.width / CGFloat(values.count - 1)
                
                for (index, value) in values.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                    let y = geometry.size.height * (1 - normalizedValue)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(gradient, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: Spacing.md) {
        AdaptiveFTPCard(onTap: {})
        AdaptiveFTPCard(onTap: {})
    }
    .padding()
    .background(Color.background.primary)
}
