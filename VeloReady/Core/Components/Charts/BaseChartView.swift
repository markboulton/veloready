import SwiftUI
import Charts

/// Base chart view with consistent styling and layout
/// Provides standard container for all chart components
struct BaseChartView<Content: View>: View {
    let title: String
    let subtitle: String?
    let isEmpty: Bool
    let emptyMessage: String
    let content: () -> Content
    
    init(
        title: String,
        subtitle: String? = nil,
        isEmpty: Bool = false,
        emptyMessage: String = "No data available",
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isEmpty = isEmpty
        self.emptyMessage = emptyMessage
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.heading)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .captionStyle()
                }
            }
            
            // Chart content or empty state
            if isEmpty {
                EmptyStateCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Data",
                    message: emptyMessage
                )
            } else {
                content()
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    let sampleData = (0..<7).map { day in
        (day: day, value: 60 + Double.random(in: 0...20))
    }
    
    return ScrollView {
        VStack(spacing: 20) {
            BaseChartView(
                title: "Heart Rate",
                subtitle: "Last 7 days"
            ) {
                Chart {
                    ForEach(sampleData, id: \.day) { data in
                        LineMark(
                            x: .value("Day", data.day),
                            y: .value("BPM", data.value)
                        )
                    }
                }
            }
            
            BaseChartView(
                title: "Power",
                isEmpty: true,
                emptyMessage: "No power data available"
            ) {
                EmptyView()
            }
        }
        .padding()
    }
}
