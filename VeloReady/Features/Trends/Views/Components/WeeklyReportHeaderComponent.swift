import SwiftUI

/// Header component for Weekly Performance Report with AI summary
struct WeeklyReportHeaderComponent: View {
    let aiSummary: String?
    let aiError: String?
    let isLoading: Bool
    let weekStartDate: Date
    let daysUntilNextReport: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: Icons.System.sparkles)
                    .font(.heading)
                    .foregroundColor(Color.text.secondary)
                
                Text(TrendsContent.WeeklyReport.title)
                    .font(.heading)
                    .foregroundColor(Color.white)
                
                Spacer()
            }
            .padding(.top, Spacing.xxl)
            .padding(.bottom, 12)
            
            // Date range
            Text(formatWeekRange())
                .font(.caption)
                .foregroundColor(.text.secondary)
                .padding(.bottom, 8)
            
            // AI Summary Content
            if isLoading {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(TrendsContent.WeeklyReport.analyzing)
                        .bodyStyle()
                        .foregroundColor(.text.secondary)
                }
                .padding(.vertical, Spacing.md)
            } else if let summary = aiSummary {
                Text(summary)
                    .bodyStyle()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)
            } else if let error = aiError {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(TrendsContent.WeeklyReport.unableToGenerate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
                .padding(.bottom, 12)
            }
            
            // Next report countdown
            if daysUntilNextReport > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: Icons.Training.duration)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                    Text("\(TrendsContent.WeeklyReport.nextReport) \(daysUntilNextReport) \(daysUntilNextReport == 1 ? TrendsContent.WeeklyReport.daySingular : TrendsContent.WeeklyReport.daysPlural)")
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
            } else {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: Icons.Status.successFill)
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(TrendsContent.WeeklyReport.generatedToday)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
    
    private func formatWeekRange() -> String {
        let calendar = Calendar.current
        let monday = weekStartDate
        guard let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: monday)) - \(formatter.string(from: sunday))"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        WeeklyReportHeaderComponent(
            aiSummary: "You pushed a solid building week with 486 TSS, but recovery dropped 8% as load increased. Sleep consistency at 82/100 and stable HRV kept you functional.",
            aiError: nil,
            isLoading: false,
            weekStartDate: Date(),
            daysUntilNextReport: 3
        )
        .padding()
        
        WeeklyReportHeaderComponent(
            aiSummary: nil,
            aiError: nil,
            isLoading: true,
            weekStartDate: Date(),
            daysUntilNextReport: 3
        )
        .padding()
    }
    .background(Color.background.primary)
}
