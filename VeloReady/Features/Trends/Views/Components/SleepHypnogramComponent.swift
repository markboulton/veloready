import SwiftUI

/// Sleep hypnogram component with segmented control for day selection
struct SleepHypnogramComponent: View {
    let hypnograms: [WeeklyReportViewModel.SleepNightData]
    @Binding var selectedDay: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(TrendsContent.WeeklyReport.weeklySleep)
                .font(.heading)
            
            if hypnograms.isEmpty {
                Text(TrendsContent.WeeklyReport.noSleepData)
                    .font(.caption)
                    .foregroundColor(.text.secondary)
            } else {
                // Segmented control for day selection
                if hypnograms.count > 1 {
                    SegmentedControl(
                        segments: hypnograms.indices.map { index in
                            SegmentItem(
                                value: index,
                                label: dayLabel(for: hypnograms[index].date)
                            )
                        },
                        selection: $selectedDay
                    )
                    .padding(.bottom, 8)
                }
                
                // Selected hypnogram with animation
                if selectedDay < hypnograms.count {
                    let hypnogram = hypnograms[selectedDay]
                    
                    VStack(alignment: .leading, spacing: 8) {
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
    
    private func formatNightDuration(_ hypnogram: WeeklyReportViewModel.SleepNightData) -> String {
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

private func generateMockHypnograms() -> [WeeklyReportViewModel.SleepNightData] {
    let calendar = Calendar.current
    return (0..<7).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: Date())!
        let bedtime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date)!
        let wakeTime = calendar.date(byAdding: .hour, value: 7, to: bedtime)!
        
        return WeeklyReportViewModel.SleepNightData(
            date: date,
            samples: [],
            bedtime: bedtime,
            wakeTime: wakeTime
        )
    }
}
