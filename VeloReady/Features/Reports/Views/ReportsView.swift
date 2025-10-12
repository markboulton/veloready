import SwiftUI

/// Reports view - placeholder for AI reporting features
struct ReportsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 80))
                    .foregroundColor(.blue.opacity(0.6))
                
                // Title
                Text(ReportsContent.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Description
                Text(ReportsContent.comingSoon)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Feature list
                VStack(alignment: .leading, spacing: 12) {
                    ReportFeatureRow(icon: "brain", text: ReportsContent.Features.aiAnalysis)
                    ReportFeatureRow(icon: "chart.line.uptrend.xyaxis", text: ReportsContent.Features.trends)
                    ReportFeatureRow(icon: "target", text: ReportsContent.Features.goalTracking)
                    ReportFeatureRow(icon: "calendar", text: ReportsContent.Features.summaries)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Spacer()
                Spacer()
            }
            .navigationTitle(ReportsContent.title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Report Feature Row

private struct ReportFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color.button.primary)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    ReportsView()
}
