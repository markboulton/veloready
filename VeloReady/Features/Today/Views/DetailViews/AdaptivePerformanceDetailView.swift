import SwiftUI
import Charts

/// Adaptive Performance detail page showing FTP, VO2 Max, and zones
struct AdaptivePerformanceDetailView: View {
    @StateObject private var viewModel = AdaptivePerformanceViewModel()
    @Environment(\.dismiss) private var dismiss
    
    enum MetricType {
        case ftp
        case vo2max
    }
    
    let initialMetric: MetricType
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md, pinnedViews: []) {
                // Hero Section
                HeroMetricsCard(
                    ftpValue: viewModel.ftpValue,
                    ftpWPerKg: viewModel.ftpWPerKg,
                    ftpCategory: viewModel.ftpCategory,
                    vo2Value: viewModel.vo2Value,
                    vo2Category: viewModel.vo2Category,
                    lastUpdated: viewModel.lastUpdated,
                    dataQuality: viewModel.dataQuality,
                    dataSource: viewModel.dataSource
                )
                
                // Historical Performance Chart (6 months)
                HistoricalPerformanceCard(
                    historicalData: viewModel.historicalData
                )
                
                // Power Zones
                PowerZonesCard(
                    zones: viewModel.powerZones,
                    ftp: viewModel.ftpValue
                )
                
                // Heart Rate Zones
                HeartRateZonesCard(
                    zones: viewModel.hrZones,
                    maxHR: viewModel.maxHR,
                    lthr: viewModel.lthr
                )
                
                // Performance Metrics
                PerformanceMetricsCard(
                    ftpTrend: viewModel.ftpTrend,
                    wPerKgRatio: viewModel.ftpWPerKg,
                    vo2Category: viewModel.vo2Category
                )
                
                // Data Quality
                DataQualityCard(
                    quality: viewModel.dataQuality,
                    sampleSize: viewModel.sampleSize,
                    lastRecalculated: viewModel.lastUpdated
                )
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.tabBarBottomPadding)
        }
        .navigationTitle("Adaptive Performance")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await viewModel.load()
            }
        }
    }
}

// MARK: - Hero Metrics Card

struct HeroMetricsCard: View {
    let ftpValue: String
    let ftpWPerKg: String
    let ftpCategory: String
    let vo2Value: String
    let vo2Category: String
    let lastUpdated: String
    let dataQuality: Double
    let dataSource: String
    
    var body: some View {
        CardContainer(
            header: CardHeader(title: "Current Performance"),
            style: .standard
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // FTP Section
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("Adaptive FTP", style: .caption, color: .secondary)
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        VRText(ftpValue, style: .largeTitle)
                        VRText("W", style: .body)
                            .foregroundColor(.secondary)
                        Spacer()
                        VRText(ftpWPerKg, style: .headline)
                            .foregroundColor(.secondary)
                        VRText(ftpCategory, style: .body, color: ColorScale.greenAccent)
                    }
                }
                
                Divider()
                
                // VO2 Max Section
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("VO₂ Max", style: .caption, color: .secondary)
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        VRText(vo2Value, style: .largeTitle)
                        VRText("ml/kg/min", style: .caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        VRText(vo2Category, style: .body, color: ColorScale.greenAccent)
                    }
                }
                
                Divider()
                
                // Metadata
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        VRText("Last updated: \(lastUpdated)", style: .caption, color: .secondary)
                        VRText("Data source: \(dataSource)", style: .caption, color: .secondary)
                    }
                    Spacer()
                    HStack(spacing: Spacing.xs) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(dataQuality * 5) ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(ColorScale.amberAccent)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Historical Performance Card

struct HistoricalPerformanceCard: View {
    let historicalData: [PerformanceDataPoint]
    @State private var selectedMetric: PerformanceMetric = .ftp

    enum PerformanceMetric: String, CaseIterable {
        case ftp = "FTP"
        case vo2 = "VO₂ Max"
    }
    
    // Calculate very adaptive Y-axis domain to show variation
    // Uses ±20% padding OR minimum 10% range to ensure variation is visible
    private var yAxisDomain: ClosedRange<Double> {
        let values = historicalData.map { selectedMetric == .ftp ? $0.ftp : ($0.vo2 ?? 0) }
        guard let minValue = values.min(), let maxValue = values.max(), minValue > 0 else {
            return 0...100
        }

        let range = maxValue - minValue

        // Use 20% padding OR minimum 10% of mean value (whichever is larger)
        // This ensures we always zoom in enough to see variation
        let meanValue = (maxValue + minValue) / 2
        let minRange = meanValue * 0.1  // Minimum 10% range of mean value
        let effectiveRange = max(range, minRange)

        let padding = effectiveRange * 0.2  // 20% padding around the effective range
        let lowerBound = max(0, minValue - padding)
        let upperBound = maxValue + padding

        return lowerBound...upperBound
    }

    var body: some View {
        CardContainer(
            header: CardHeader(title: "6-Month Trend"),
            style: .standard
        ) {
            if !historicalData.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Metric selector
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(PerformanceMetric.allCases, id: \.self) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Chart with confidence intervals
                    Chart(historicalData) { dataPoint in
                        // Confidence interval (shaded area)
                        if selectedMetric == .ftp {
                            AreaMark(
                                x: .value("Date", dataPoint.date),
                                yStart: .value("Lower", dataPoint.ftpLowerBound),
                                yEnd: .value("Upper", dataPoint.ftpUpperBound)
                            )
                            .foregroundStyle(ColorScale.purpleAccent.opacity(0.15))
                            .interpolationMethod(.catmullRom)
                        } else if let vo2Lower = dataPoint.vo2LowerBound, let vo2Upper = dataPoint.vo2UpperBound {
                            AreaMark(
                                x: .value("Date", dataPoint.date),
                                yStart: .value("Lower", vo2Lower),
                                yEnd: .value("Upper", vo2Upper)
                            )
                            .foregroundStyle(ColorScale.blueAccent.opacity(0.15))
                            .interpolationMethod(.catmullRom)
                        }
                        
                        // Main line
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", selectedMetric == .ftp ? dataPoint.ftp : (dataPoint.vo2 ?? 0))
                        )
                        .foregroundStyle(selectedMetric == .ftp ? ColorScale.purpleAccent : ColorScale.blueAccent)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                        
                        // Low confidence indicator (smaller points)
                        if dataPoint.confidence < 0.5 {
                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Value", selectedMetric == .ftp ? dataPoint.ftp : (dataPoint.vo2 ?? 0))
                            )
                            .foregroundStyle(ColorScale.amberAccent)
                            .symbolSize(30)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .font(.caption)
                                .foregroundStyle(Color.text.secondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel()
                                .font(.caption)
                                .foregroundStyle(Color.text.secondary)
                        }
                    }
                    .chartYScale(domain: yAxisDomain)
                    .frame(height: 200)

                    // Summary stats
                    if let first = historicalData.first, let last = historicalData.last {
                        let startValue = selectedMetric == .ftp ? first.ftp : (first.vo2 ?? 0)
                        let endValue = selectedMetric == .ftp ? last.ftp : (last.vo2 ?? 0)
                        let change = ((endValue - startValue) / startValue) * 100
                        let unit = selectedMetric == .ftp ? "W" : "ml/kg/min"

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                VRText("Start", style: .caption, color: .secondary)
                                VRText("\(Int(startValue)) \(unit)", style: .body)
                            }

                            Spacer()

                            VStack(alignment: .center, spacing: 2) {
                                VRText("Change", style: .caption, color: .secondary)
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: change >= 0 ? Icons.Arrow.upRight : Icons.Arrow.downRight)
                                        .font(.caption)
                                        .foregroundColor(change >= 0 ? ColorScale.greenAccent : ColorScale.redAccent)
                                    VRText(
                                        "\(change >= 0 ? "+" : "")\(String(format: "%.1f", change))%",
                                        style: .body,
                                        color: change >= 0 ? ColorScale.greenAccent : ColorScale.redAccent
                                    )
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                VRText("Current", style: .caption, color: .secondary)
                                VRText("\(Int(endValue)) \(unit)", style: .body)
                            }
                        }
                        
                        // Legend for confidence intervals
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(spacing: Spacing.xs) {
                                Rectangle()
                                    .fill(selectedMetric == .ftp ? ColorScale.purpleAccent.opacity(0.15) : ColorScale.blueAccent.opacity(0.15))
                                    .frame(width: 16, height: 8)
                                VRText("Confidence interval (based on sample size)", style: .caption2, color: .secondary)
                            }
                            
                            HStack(spacing: Spacing.xs) {
                                Circle()
                                    .fill(ColorScale.amberAccent)
                                    .frame(width: 8, height: 8)
                                VRText("Low confidence (<50%, fewer activities)", style: .caption2, color: .secondary)
                            }
                        }
                        .padding(.top, Spacing.sm)
                    }
                }
            } else {
                VRText("No historical data available", style: .body, color: .secondary)
                    .frame(height: 150)
            }
        }
    }
}

// MARK: - Power Zones Card

struct PowerZonesCard: View {
    let zones: [PowerZone]
    let ftp: String
    
    var body: some View {
        CardContainer(
            header: CardHeader(title: "Power Zones"),
            style: .standard
        ) {
            VStack(spacing: Spacing.sm) {
                ForEach(zones) { zone in
                    PowerZoneRow(zone: zone)
                    if zone.number < zones.count {
                        Divider()
                    }
                }
            }
        }
    }
}

struct PowerZoneRow: View {
    let zone: PowerZone
    
    var body: some View {
        HStack {
            // Zone indicator
            Circle()
                .fill(zone.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                VRText("Z\(zone.number) \(zone.name)", style: .body)
                VRText("\(zone.percentage)", style: .caption, color: .secondary)
            }
            
            Spacer()
            
            VRText(zone.range, style: .headline)
        }
    }
}

// MARK: - Heart Rate Zones Card

struct HeartRateZonesCard: View {
    let zones: [HRZone]
    let maxHR: String
    let lthr: String
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: "Heart Rate Zones",
                subtitle: "Max: \(maxHR) • LTHR: \(lthr)"
            ),
            style: .standard
        ) {
            VStack(spacing: Spacing.sm) {
                ForEach(zones) { zone in
                    HRZoneRow(zone: zone)
                    if zone.number < zones.count {
                        Divider()
                    }
                }
            }
        }
    }
}

struct HRZoneRow: View {
    let zone: HRZone
    
    var body: some View {
        HStack {
            Circle()
                .fill(zone.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                VRText("Z\(zone.number) \(zone.name)", style: .body)
                VRText("\(zone.percentage)", style: .caption, color: .secondary)
            }
            
            Spacer()
            
            VRText(zone.range, style: .headline)
        }
    }
}

// MARK: - Performance Metrics Card

struct PerformanceMetricsCard: View {
    let ftpTrend: String
    let wPerKgRatio: String
    let vo2Category: String
    
    var body: some View {
        CardContainer(
            header: CardHeader(title: "Performance Indicators"),
            style: .standard
        ) {
            VStack(spacing: Spacing.sm) {
                MetricRow(label: "FTP Trend (30d)", value: ftpTrend, color: ColorScale.greenAccent)
                Divider()
                MetricRow(label: "W/kg Ratio", value: wPerKgRatio, color: nil)
                Divider()
                MetricRow(label: "VO₂ Max Category", value: vo2Category, color: nil)
            }
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let color: Color?
    
    var body: some View {
        HStack {
            VRText(label, style: .body, color: .secondary)
            Spacer()
            VRText(value, style: .headline, color: color)
        }
    }
}

// MARK: - Data Quality Card

struct DataQualityCard: View {
    let quality: Double
    let sampleSize: Int
    let lastRecalculated: String
    
    var body: some View {
        CardContainer(
            header: CardHeader(title: "Data Quality"),
            style: .standard
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(quality * 5) ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundColor(ColorScale.amberAccent)
                    }
                    Spacer()
                    VRText("\(Int(quality * 100))% Confidence", style: .headline)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("Based on:", style: .caption, color: .secondary)
                    VRText("• \(sampleSize) rides with power data", style: .body)
                    VRText("• Consistent training pattern", style: .body)
                }
                
                Divider()
                
                HStack {
                    VRText("Last recalculated", style: .caption, color: .secondary)
                    Spacer()
                    VRText(lastRecalculated, style: .body)
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class AdaptivePerformanceViewModel: ObservableObject {
    @Published var ftpValue: String = "—"
    @Published var ftpWPerKg: String = "—"
    @Published var ftpCategory: String = "—"
    @Published var vo2Value: String = "—"
    @Published var vo2Category: String = "—"
    @Published var lastUpdated: String = "—"
    @Published var dataQuality: Double = 0.0
    @Published var sampleSize: Int = 0
    
    @Published var powerZones: [PowerZone] = []
    @Published var hrZones: [HRZone] = []
    @Published var historicalData: [PerformanceDataPoint] = []
    
    @Published var maxHR: String = "—"
    @Published var lthr: String = "—"
    @Published var ftpTrend: String = "—"
    @Published var dataSource: String = "Estimated" // "Estimated", "HR-based", or "Power-based"

    private let profileManager = AthleteProfileManager.shared
    private let proConfig = ProFeatureConfig.shared

    func load() async {
        let profile = profileManager.profile
        let hasPro = proConfig.hasProAccess

        // Determine data source and values based on three-tier system
        var ftp: Double = 0
        var vo2: Double?

        if hasPro {
            // Pro user: Check for power meter data
            do {
                let activities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 50, daysBack: 90)
                let hasPowerMeter = AthleteProfileManager.hasPowerMeterData(activities: activities)

                if hasPowerMeter {
                    // Tier 3: Pro with power meter - use adaptive values
                    ftp = profile.ftp ?? 0
                    vo2 = profile.vo2maxEstimate
                    dataSource = "Power-based"
                } else {
                    // Tier 2: Pro without power meter - estimate from HR
                    if let maxHR = profile.maxHR, let lthr = profile.lthr, let weight = profile.weight {
                        ftp = AthleteProfileManager.estimateFTPFromHR(maxHR: maxHR, lthr: lthr, weight: weight) ?? 0
                        vo2 = AthleteProfileManager.estimateVO2MaxFromHR(maxHR: maxHR, restingHR: profile.restingHR, age: nil)
                        dataSource = "HR-based"
                    } else {
                        // Fallback to Coggan defaults
                        ftp = AthleteProfileManager.getCogganDefaultFTP(weight: profile.weight)
                        vo2 = AthleteProfileManager.getCogganDefaultVO2Max(age: nil, gender: profile.sex)
                        dataSource = "Estimated"
                    }
                }
            } catch {
                // Fallback to existing values or Coggan defaults
                ftp = profile.ftp ?? AthleteProfileManager.getCogganDefaultFTP(weight: profile.weight)
                vo2 = profile.vo2maxEstimate ?? AthleteProfileManager.getCogganDefaultVO2Max(age: nil, gender: profile.sex)
                dataSource = profile.ftp != nil ? "Power-based" : "Estimated"
            }
        } else {
            // Tier 1: Free user - use Coggan defaults
            ftp = AthleteProfileManager.getCogganDefaultFTP(weight: profile.weight)
            vo2 = AthleteProfileManager.getCogganDefaultVO2Max(age: nil, gender: profile.sex)
            dataSource = "Estimated"
        }

        // FTP Data
        if ftp > 0 {
            ftpValue = "\(Int(ftp))"

            if let weight = profile.weight, weight > 0 {
                let wPerKg = ftp / weight
                ftpWPerKg = "\(String(format: "%.1f", wPerKg)) W/kg"
                ftpCategory = categorizeFTPWPerKg(wPerKg)
            }
        }

        // VO2 Data
        if let vo2 = vo2 {
            vo2Value = String(format: "%.1f", vo2)
            vo2Category = categorizeVO2Max(vo2)
        }
        
        // Data Quality
        if let quality = profile.dataQuality {
            dataQuality = quality.confidenceScore
            sampleSize = quality.sampleSize
        } else {
            dataQuality = 0.75 // Default estimate
            sampleSize = 20
        }
        
        // Last Updated
        if let lastComputed = profile.lastComputedFromActivities {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            lastUpdated = formatter.localizedString(for: lastComputed, relativeTo: Date())
        }
        
        // Power Zones
        powerZones = generatePowerZones(ftp: profile.ftp ?? 0)
        
        // HR Zones
        if let maxHR = profile.maxHR {
            self.maxHR = "\(Int(maxHR)) bpm"
            hrZones = generateHRZones(maxHR: maxHR)
        }
        
        if let lthr = profile.lthr {
            self.lthr = "\(Int(lthr)) bpm"
        }

        // Load historical performance data asynchronously
        Task {
            let historical = await profileManager.fetch6MonthHistoricalPerformance()

            await MainActor.run {
                // Convert to PerformanceDataPoint with confidence intervals
                historicalData = historical.map { dataPoint in
                    PerformanceDataPoint(
                        date: dataPoint.date,
                        ftp: dataPoint.ftp,
                        vo2: dataPoint.vo2,
                        confidence: dataPoint.confidence,
                        activityCount: dataPoint.activityCount
                    )
                }

                // Calculate FTP trend from first to last data point
                if let first = historical.first, let last = historical.last, first.ftp > 0 {
                    let change = ((last.ftp - first.ftp) / first.ftp) * 100
                    if change > 0 {
                        ftpTrend = "+\(String(format: "%.1f", change))% ↗"
                    } else {
                        ftpTrend = "\(String(format: "%.1f", change))% ↘"
                    }
                }
            }
        }
    }
    
    private func generatePowerZones(ftp: Double) -> [PowerZone] {
        guard ftp > 0 else { return [] }
        
        return [
            PowerZone(number: 1, name: "Recovery", percentage: "<60%", range: "<\(Int(ftp * 0.6))W", color: ColorScale.blueAccent.opacity(0.5)),
            PowerZone(number: 2, name: "Endurance", percentage: "60-80%", range: "\(Int(ftp * 0.6))-\(Int(ftp * 0.8))W", color: ColorScale.blueAccent),
            PowerZone(number: 3, name: "Tempo", percentage: "80-90%", range: "\(Int(ftp * 0.8))-\(Int(ftp * 0.9))W", color: ColorScale.greenAccent),
            PowerZone(number: 4, name: "Threshold", percentage: "90-100%", range: "\(Int(ftp * 0.9))-\(Int(ftp))W", color: ColorScale.amberAccent),
            PowerZone(number: 5, name: "VO2 Max", percentage: "100-110%", range: "\(Int(ftp))-\(Int(ftp * 1.1))W", color: ColorScale.yellowAccent),
            PowerZone(number: 6, name: "Anaerobic", percentage: "110-130%", range: "\(Int(ftp * 1.1))-\(Int(ftp * 1.3))W", color: ColorScale.redAccent),
            PowerZone(number: 7, name: "Neuromuscular", percentage: ">130%", range: ">\(Int(ftp * 1.3))W", color: ColorScale.purpleAccent)
        ]
    }
    
    private func generateHRZones(maxHR: Double) -> [HRZone] {
        return [
            HRZone(number: 1, name: "Recovery", percentage: "<65%", range: "<\(Int(maxHR * 0.65)) bpm", color: ColorScale.blueAccent.opacity(0.5)),
            HRZone(number: 2, name: "Endurance", percentage: "65-75%", range: "\(Int(maxHR * 0.65))-\(Int(maxHR * 0.75)) bpm", color: ColorScale.blueAccent),
            HRZone(number: 3, name: "Tempo", percentage: "75-85%", range: "\(Int(maxHR * 0.75))-\(Int(maxHR * 0.85)) bpm", color: ColorScale.greenAccent),
            HRZone(number: 4, name: "Threshold", percentage: "85-90%", range: "\(Int(maxHR * 0.85))-\(Int(maxHR * 0.9)) bpm", color: ColorScale.amberAccent),
            HRZone(number: 5, name: "VO2 Max", percentage: "90-95%", range: "\(Int(maxHR * 0.9))-\(Int(maxHR * 0.95)) bpm", color: ColorScale.yellowAccent),
            HRZone(number: 6, name: "Anaerobic", percentage: ">95%", range: ">\(Int(maxHR * 0.95)) bpm", color: ColorScale.redAccent)
        ]
    }
    
    private func categorizeFTPWPerKg(_ wPerKg: Double) -> String {
        if wPerKg >= 5.0 { return "World Class" }
        if wPerKg >= 4.5 { return "Excellent" }
        if wPerKg >= 4.0 { return "Very Good" }
        if wPerKg >= 3.5 { return "Good" }
        if wPerKg >= 3.0 { return "Fair" }
        return "Developing"
    }
    
    private func categorizeVO2Max(_ vo2: Double) -> String {
        if vo2 >= 55 { return "Superior" }
        if vo2 >= 50 { return "Excellent" }
        if vo2 >= 45 { return "Good" }
        if vo2 >= 40 { return "Fair" }
        return "Average"
    }
}

// MARK: - Data Models

struct PowerZone: Identifiable {
    let id = UUID()
    let number: Int
    let name: String
    let percentage: String
    let range: String
    let color: Color
}

struct HRZone: Identifiable {
    let id = UUID()
    let number: Int
    let name: String
    let percentage: String
    let range: String
    let color: Color
}

struct PerformanceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let ftp: Double
    let vo2: Double?
    let confidence: Double  // 0.0 to 1.0, based on sample size
    let activityCount: Int  // Total activities in window
    
    // Confidence interval bounds (±5% scaled by confidence)
    var ftpLowerBound: Double {
        ftp * (1.0 - (0.05 * (1.0 - confidence)))
    }
    var ftpUpperBound: Double {
        ftp * (1.0 + (0.05 * (1.0 - confidence)))
    }
    var vo2LowerBound: Double? {
        guard let vo2 = vo2 else { return nil }
        return vo2 * (1.0 - (0.05 * (1.0 - confidence)))
    }
    var vo2UpperBound: Double? {
        guard let vo2 = vo2 else { return nil }
        return vo2 * (1.0 + (0.05 * (1.0 - confidence)))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdaptivePerformanceDetailView(initialMetric: .ftp)
    }
}
