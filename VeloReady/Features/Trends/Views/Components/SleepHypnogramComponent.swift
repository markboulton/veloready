import SwiftUI

/// Sleep hypnogram component with segmented control for day selection
struct SleepHypnogramComponent: View {
    let hypnograms: [SleepNightData]
    @Binding var selectedDay: Int
    
    var body: some View {
        StandardCard(
            title: TrendsContent.WeeklyReport.weeklySleep
        ) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if hypnograms.isEmpty {
                Text(TrendsContent.WeeklyReport.noSleepData)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            } else {
                // Segmented control for day selection (limit to last 7 days to avoid overflow)
                if hypnograms.count > 1 {
                    let displayedHypnograms = Array(hypnograms.suffix(min(7, hypnograms.count)))
                    let startIndex = hypnograms.count - displayedHypnograms.count
                    
                    LiquidGlassSegmentedControl(
                        segments: displayedHypnograms.indices.map { localIndex in
                            let globalIndex = startIndex + localIndex
                            return SegmentItem(
                                value: globalIndex,
                                label: dayLabel(for: hypnograms[globalIndex].date)
                            )
                        },
                        selection: $selectedDay
                    )
                    .padding(.bottom, 8)
                    
                    // Show indicator if there are more days available
                    if hypnograms.count > 7 {
                        Text("\(hypnograms.count) days available")
                            .font(.caption2)
                            .foregroundColor(.text.tertiary)
                            .padding(.bottom, 4)
                    }
                }
                
                // Selected hypnogram with animation
                if selectedDay < hypnograms.count {
                    let hypnogram = hypnograms[selectedDay]
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(formatHypnogramDate(hypnogram.date))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatNightDuration(hypnogram))
                                .font(.caption)
                                .foregroundColor(.text.secondary)
                        }
                        
                        SleepHypnogramChart(
                            sleepSamples: hypnogram.samples,
                            nightStart: hypnogram.bedtime,
                            nightEnd: hypnogram.wakeTime
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .id(selectedDay) // Force view recreation for animation
                    }
                    .animation(.easeInOut(duration: 0.25), value: selectedDay)
                }
            }
            }
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatHypnogramDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func formatNightDuration(_ hypnogram: SleepNightData) -> String {
        let duration = hypnogram.wakeTime.timeIntervalSince(hypnogram.bedtime)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedDay = 0
        
        var body: some View {
            SleepHypnogramComponent(
                hypnograms: generateMockHypnograms(),
                selectedDay: $selectedDay
            )
            .padding()
            .background(Color.background.primary)
        }
    }
    
    return PreviewWrapper()
}

private func generateMockHypnograms() -> [SleepNightData] {
    let calendar = Calendar.current
    return (0..<7).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: Date())!
        let bedtime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date)!
        let wakeTime = calendar.date(byAdding: .hour, value: 7, to: bedtime)!
        
        return SleepNightData(
            date: date,
            samples: [],
            bedtime: bedtime,
            wakeTime: wakeTime
        )
    }
}
