import SwiftUI

/// Reusable chart legend component
/// Displays color-coded legend items for charts
struct ChartLegend: View {
    let items: [ChartLegendItem]
    let columns: Int
    
    init(items: [ChartLegendItem], columns: Int = 2) {
        self.items = items
        self.columns = columns
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 8) {
            ForEach(items) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)
                    
                    Text(item.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let value = item.value {
                        Text(value)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

struct ChartLegendItem: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
    let value: String?
    
    init(label: String, color: Color, value: String? = nil) {
        self.label = label
        self.color = color
        self.value = value
    }
}

#Preview {
    VStack(spacing: 20) {
        ChartLegend(items: [
            ChartLegendItem(label: "Zone 1", color: .blue, value: "12m"),
            ChartLegendItem(label: "Zone 2", color: .green, value: "28m"),
            ChartLegendItem(label: "Zone 3", color: .yellow, value: "15m"),
            ChartLegendItem(label: "Zone 4", color: .orange, value: "5m")
        ])
        
        ChartLegend(items: [
            ChartLegendItem(label: "Sleep", color: .purple),
            ChartLegendItem(label: "Recovery", color: .green),
            ChartLegendItem(label: "Load", color: .orange)
        ], columns: 3)
    }
    .padding()
}
