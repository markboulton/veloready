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
                   recoveryScore: 75, recoveryBand: "Good", isPersonalized: false)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let (score, band, isPersonalized) = await fetchRecoveryScore()
        return SimpleEntry(date: Date(), configuration: configuration,
                          recoveryScore: score, recoveryBand: band, isPersonalized: isPersonalized)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let (score, band, isPersonalized) = await fetchRecoveryScore()
        let currentDate = Date()
        
        // Create single entry for current recovery score
        let entry = SimpleEntry(date: currentDate, configuration: configuration,
                               recoveryScore: score, recoveryBand: band, isPersonalized: isPersonalized)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func fetchRecoveryScore() async -> (Int?, String?, Bool) {
        // Try to read from shared UserDefaults (App Group)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") {
            let score = sharedDefaults.integer(forKey: "cachedRecoveryScore")
            let band = sharedDefaults.string(forKey: "cachedRecoveryBand")
            let isPersonalized = sharedDefaults.bool(forKey: "cachedRecoveryIsPersonalized")
            
            if score > 0 {
                return (score, band, isPersonalized)
            }
        }
        return (nil, nil, false)
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
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), recoveryScore: 85, recoveryBand: "Optimal", isPersonalized: true)
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), recoveryScore: 65, recoveryBand: "Good", isPersonalized: false)
}
