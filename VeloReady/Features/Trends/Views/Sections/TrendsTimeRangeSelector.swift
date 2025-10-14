import SwiftUI

/// Time range selector for trends view
struct TrendsTimeRangeSelector: View {
    @ObservedObject var viewModel: TrendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Time Range")
                .font(.caption)
                .foregroundColor(.text.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(TrendsViewModel.TimeRange.allCases, id: \.self) { range in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedTimeRange = range
                            }
                            Task {
                                await viewModel.loadTrendData()
                            }
                        }) {
                            Text(range.rawValue)
                                .font(.button)
                                .foregroundColor(
                                    viewModel.selectedTimeRange == range ? .white : .text.primary
                                )
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(
                                    viewModel.selectedTimeRange == range ?
                                    Color.button.primary : Color.background.secondary
                                )
                                .cornerRadius(Spacing.buttonCornerRadius)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}
