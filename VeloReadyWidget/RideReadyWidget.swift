//
//  VeloReadyWidget.swift
//  VeloReadyWidget
//
//  Created by Mark Boulton on 30/09/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), 
                   recoveryScore: 75, recoveryBand: "Good", isPersonalized: false,
                   sleepScore: 85, strainScore: 8.5)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let data = await fetchAllScores()
        return SimpleEntry(date: Date(), configuration: configuration,
                          recoveryScore: data.recovery, recoveryBand: data.band, isPersonalized: data.isPersonalized,
                          sleepScore: data.sleep, strainScore: data.strain)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let data = await fetchAllScores()
        let currentDate = Date()
        
        // Create single entry for current scores
        let entry = SimpleEntry(date: currentDate, configuration: configuration,
                               recoveryScore: data.recovery, recoveryBand: data.band, isPersonalized: data.isPersonalized,
                               sleepScore: data.sleep, strainScore: data.strain)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func fetchAllScores() async -> (recovery: Int?, band: String?, isPersonalized: Bool, sleep: Int?, strain: Double?) {
        // Try to read from shared UserDefaults (App Group)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") {
            let recovery = sharedDefaults.integer(forKey: "cachedRecoveryScore")
            let band = sharedDefaults.string(forKey: "cachedRecoveryBand")
            let isPersonalized = sharedDefaults.bool(forKey: "cachedRecoveryIsPersonalized")
            let sleep = sharedDefaults.integer(forKey: "cachedSleepScore")
            let strain = sharedDefaults.double(forKey: "cachedStrainScore")
            
            if recovery > 0 {
                return (recovery, band, isPersonalized, sleep > 0 ? sleep : nil, strain > 0 ? strain : nil)
            }
        }
        return (nil, nil, false, nil, nil)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let recoveryScore: Int?
    let recoveryBand: String?
    let isPersonalized: Bool
    let sleepScore: Int?
    let strainScore: Double?
}

struct VeloReadyWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularRecoveryView(score: entry.recoveryScore, isPersonalized: entry.isPersonalized)
        case .accessoryRectangular:
            RectangularRecoveryView(score: entry.recoveryScore, band: entry.recoveryBand, isPersonalized: entry.isPersonalized)
        case .accessoryInline:
            InlineRecoveryView(score: entry.recoveryScore)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallRecoveryView(score: entry.recoveryScore, band: entry.recoveryBand, isPersonalized: entry.isPersonalized)
        }
    }
}

// MARK: - Widget Views

struct CircularRecoveryView: View {
    let score: Int?
    let isPersonalized: Bool
    
    var body: some View {
        ZStack {
            if let score = score {
                Gauge(value: Double(score), in: 0...100) {
                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 24, weight: .bold))
                        if isPersonalized {
                            Image(systemName: "sparkles")
                                .font(.system(size: 8))
                        }
                    }
                } currentValueLabel: {
                    Text("\(score)")
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                Text("--")
                    .font(.system(size: 24, weight: .bold))
            }
        }
    }
}

struct RectangularRecoveryView: View {
    let score: Int?
    let band: String?
    let isPersonalized: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Recovery")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if isPersonalized {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8))
                    }
                }
                if let score = score {
                    Text("\(score)")
                        .font(.system(size: 32, weight: .bold))
                    Text(band ?? "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("--")
                        .font(.system(size: 32, weight: .bold))
                }
            }
            Spacer()
        }
    }
}

struct InlineRecoveryView: View {
    let score: Int?
    
    var body: some View {
        if let score = score {
            Text("Recovery: \(score)")
        } else {
            Text("Recovery: --")
        }
    }
}

struct SmallRecoveryView: View {
    let score: Int?
    let band: String?
    let isPersonalized: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("Recovery")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if isPersonalized {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.purple)
                }
            }
            
            if let score = score {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(colorForScore(score))
                
                Text(band ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.secondary)
                
                Text("No Data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 16) {
            // Recovery Ring
            VStack(spacing: 6) {
                Text("Recovery")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .textCase(.lowercase)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 7)
                        .frame(width: 70, height: 70)
                    
                    if let score = entry.recoveryScore {
                        Circle()
                            .trim(from: 0, to: Double(score) / 100.0)
                            .stroke(colorForRecoveryScore(score), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(score)")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(colorForRecoveryScore(score))
                            
                            if entry.isPersonalized {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 7))
                                    .foregroundColor(.purple)
                            }
                        }
                    } else {
                        Text("--")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                
                Text(entry.recoveryBand ?? "--")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.lowercase)
            }
            
            // Sleep Ring
            VStack(spacing: 6) {
                Text("Sleep")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .textCase(.lowercase)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 7)
                        .frame(width: 70, height: 70)
                    
                    if let score = entry.sleepScore {
                        Circle()
                            .trim(from: 0, to: Double(score) / 100.0)
                            .stroke(colorForSleepScore(score), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(score)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(colorForSleepScore(score))
                    } else {
                        Text("--")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                
                Text(sleepBandForScore(entry.sleepScore))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.lowercase)
            }
            
            // Strain Ring
            VStack(spacing: 6) {
                Text("Strain")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .textCase(.lowercase)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 7)
                        .frame(width: 70, height: 70)
                    
                    if let strain = entry.strainScore {
                        Circle()
                            .trim(from: 0, to: min(strain / 21.0, 1.0)) // Max strain is 21
                            .stroke(colorForStrain(strain), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        
                        Text(String(format: "%.1f", strain))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(colorForStrain(strain))
                    } else {
                        Text("--")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                
                Text(strainBandForScore(entry.strainScore))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.lowercase)
            }
        }
        .padding()
    }
    
    private func colorForRecoveryScore(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private func colorForSleepScore(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private func colorForStrain(_ strain: Double) -> Color {
        switch strain {
        case 0..<4: return .green
        case 4..<10: return .yellow
        case 10..<14: return .orange
        case 14..<18: return .red
        default: return .purple
        }
    }
    
    private func sleepBandForScore(_ score: Int?) -> String {
        guard let score = score else { return "--" }
        switch score {
        case 80...100: return "optimal"
        case 60..<80: return "good"
        case 40..<60: return "fair"
        default: return "poor"
        }
    }
    
    private func strainBandForScore(_ strain: Double?) -> String {
        guard let strain = strain else { return "--" }
        switch strain {
        case 0..<4: return "light"
        case 4..<10: return "moderate"
        case 10..<14: return "high"
        case 14..<18: return "very high"
        default: return "all out"
        }
    }
}

struct VeloReadyWidget: Widget {
    let kind: String = "VeloReadyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            VeloReadyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("VeloReady")
        .description("View your recovery score at a glance")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    VeloReadyWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), recoveryScore: 85, recoveryBand: "Optimal", isPersonalized: true, sleepScore: 90, strainScore: 8.5)
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), recoveryScore: 65, recoveryBand: "Good", isPersonalized: false, sleepScore: 75, strainScore: 12.3)
}

#Preview(as: .systemMedium) {
    VeloReadyWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), recoveryScore: 68, recoveryBand: "Good", isPersonalized: false, sleepScore: 84, strainScore: 8.6)
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), recoveryScore: 85, recoveryBand: "Optimal", isPersonalized: true, sleepScore: 90, strainScore: 5.2)
}
