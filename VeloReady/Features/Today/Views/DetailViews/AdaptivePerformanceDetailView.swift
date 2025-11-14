import SwiftUI

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
                    dataQuality: viewModel.dataQuality
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
                    VRText("Last updated: \(lastUpdated)", style: .caption, color: .secondary)
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
    
    var body: some View {
        CardContainer(
            header: CardHeader(title: "6-Month Trend"),
            style: .standard
        ) {
            if !historicalData.isEmpty {
                // TODO: Add line chart showing FTP progression
                VRText("Chart coming soon", style: .body, color: .secondary)
                    .frame(height: 150)
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
    
    private let profileManager = AthleteProfileManager.shared
    
    func load() async {
        let profile = profileManager.profile
        
        // FTP Data
        if let ftp = profile.ftp {
            ftpValue = "\(Int(ftp))"
            
            if let weight = profile.weight, weight > 0 {
                let wPerKg = ftp / weight
                ftpWPerKg = "\(String(format: "%.1f", wPerKg)) W/kg"
                ftpCategory = categorizeFTPWPerKg(wPerKg)
            }
        }
        
        // VO2 Data
        if let vo2 = profile.vo2maxEstimate {
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
        
        // TODO: Fetch historical data from Core Data
        ftpTrend = "+3.2% ↗"
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdaptivePerformanceDetailView(initialMetric: .ftp)
    }
}
