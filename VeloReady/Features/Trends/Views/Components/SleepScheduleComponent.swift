import SwiftUI

/// Sleep Schedule component showing circadian rhythm data
struct SleepScheduleComponent: View {
    let circadian: WeeklyReportViewModel.CircadianRhythmData
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(TrendsContent.WeeklyReport.sleepSchedule)
                .font(.heading)
            
            HStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(TrendsContent.WeeklyReport.avgBedtime)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text(formatHour(circadian.avgBedtime))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(TrendsContent.WeeklyReport.avgWake)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text(formatHour(circadian.avgWakeTime))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(TrendsContent.WeeklyReport.consistency)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text("±\(Int(circadian.bedtimeVariance)) min")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            
            Text(circadianMessage(circadian: circadian))
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
    }
    
    private func formatHour(_ hour: Double) -> String {
        let h = Int(hour.truncatingRemainder(dividingBy: 24))
        let m = Int((hour - Double(Int(hour))) * 60)
        let period = h >= 12 ? "PM" : "AM"
        let displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h)
        return String(format: "%d:%02d %@", displayHour, m, period)
    }
    
    private func circadianMessage(circadian: WeeklyReportViewModel.CircadianRhythmData) -> String {
        if circadian.bedtimeVariance < 30 {
            return TrendsContent.WeeklyReport.excellentConsistency
        } else if circadian.bedtimeVariance < 60 {
            return TrendsContent.WeeklyReport.goodConsistency
        } else {
            return TrendsContent.WeeklyReport.variableSchedule
        }
    }
}
