import SwiftUI

/// Adaptive FTP card (50% width) with RAG-colored sparkline
struct AdaptiveFTPCard: View {
    @StateObject private var viewModel = AdaptiveFTPCardViewModel()
    @State private var hasLoadedData = false
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
            HStack(alignment: .top, spacing: Spacing.lg) {
                // Left 50%: Content
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Primary metric
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        VRText(viewModel.ftpValue, style: .largeTitle)
                        VRText("W", style: .body)
                            .foregroundColor(.secondary)
                    }

                    // Secondary metric
                    if let wPerKg = viewModel.wPerKg {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            VRText(viewModel.wPerKgValue, style: .body)
                                .foregroundColor(.secondary)
                            VRText("W/kg", style: .caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Data source
                    HStack(spacing: Spacing.xs) {
                        if viewModel.dataSource == "Estimated" {
                            Image(systemName: Icons.System.lock)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        VRText(viewModel.dataSource, style: .caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right 50%: Visualization
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    if viewModel.hasData && !viewModel.historicalValues.isEmpty {
                        VRText("30 days", style: .caption, color: Color.text.secondary)

                        PerformanceSparkline(values: viewModel.historicalValues, color: ColorScale.greenAccent)
                            .frame(height: 60)
                    } else {
                        // Placeholder when no data
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title)
                                .foregroundColor(Color.text.secondary.opacity(0.3))
                            VRText(viewModel.hasData ? "Loading" : "Pro feature", style: .caption, color: Color.text.secondary)
                        }
                        .frame(height: 60)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .task {
            guard !hasLoadedData else {
                Logger.debug("⏭️ [FTPCard] Data already loaded, skipping")
                return
            }
            
            await viewModel.load()
            hasLoadedData = true
        }
        .onDisappear {
            hasLoadedData = false
        }
    }
}

// MARK: - ViewModel

@MainActor
class AdaptiveFTPCardViewModel: ObservableObject {
    @Published var ftpValue: String = "—"
    @Published var wPerKg: String?
    @Published var wPerKgValue: String = ""
    @Published var historicalValues: [Double] = []
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

        // Only show trend for PRO users with FTP data
        if hasPro, ftp > 0 {
            hasData = true

            // Load historical data for sparkline
            Task {
                let historical = await profileManager.fetch6MonthHistoricalPerformance()

                await MainActor.run {
                    // Get last 30 days of FTP data
                    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                    let recentData = historical.filter { $0.date >= thirtyDaysAgo && $0.ftp > 0 }

                    if !recentData.isEmpty {
                        historicalValues = recentData.map { $0.ftp }

                        // Calculate trend
                        if let first = recentData.first, let last = recentData.last, first.ftp > 0 {
                            let change = ((last.ftp - first.ftp) / first.ftp) * 100

                            if change > 2 {
                                trendColor = ColorScale.greenAccent
                                trendIcon = Icons.Arrow.upRight
                                trendText = "Improving"
                            } else if change < -2 {
                                trendColor = ColorScale.redAccent
                                trendIcon = Icons.Arrow.downRight
                                trendText = "Declining"
                            } else {
                                trendColor = .secondary
                                trendIcon = Icons.Arrow.right
                                trendText = "Stable"
                            }
                        }
                    }
                }
            }
        } else {
            hasData = false
        }
    }

    // Deprecated - now using cached historical data
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

// MARK: - Performance Sparkline Component

struct PerformanceSparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            guard !values.isEmpty else {
                return AnyView(EmptyView())
            }

            let maxValue = values.max() ?? 1
            let minValue = values.min() ?? 0
            let range = maxValue - minValue

            return AnyView(
                ZStack(alignment: .bottom) {
                    // Area under the curve
                    Path { path in
                        let stepX = geometry.size.width / CGFloat(max(values.count - 1, 1))

                        path.move(to: CGPoint(x: 0, y: geometry.size.height))

                        for (index, value) in values.enumerated() {
                            let x = CGFloat(index) * stepX
                            let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                            let y = geometry.size.height * (1 - normalizedValue)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }

                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        let stepX = geometry.size.width / CGFloat(max(values.count - 1, 1))

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
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            )
        }
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
