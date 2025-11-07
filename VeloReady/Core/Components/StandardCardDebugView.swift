import SwiftUI

/// Debug view to showcase StandardCard component variations
struct StandardCardDebugView: View {
    @State private var selectedCard: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Section 1: Full Featured Cards
                    sectionHeader("Full Featured")
                    
                    StandardCard(
                        icon: "figure.run",
                        iconColor: .blue,
                        title: "Today's Ride",
                        subtitle: "October 22, 2025 • 2:30 PM",
                        showChevron: true,
                        onTap: { selectedCard = "Today's Ride" }
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            metricRow(label: "Distance", value: "45.2 km")
                            metricRow(label: "Duration", value: "1h 32m")
                            metricRow(label: "TSS", value: "87")
                            metricRow(label: "Avg Power", value: "245W")
                        }
                    }
                    
                    StandardCard(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Recovery Score",
                        subtitle: "Based on HRV and sleep",
                        showChevron: true,
                        onTap: { selectedCard = "Recovery" }
                    ) {
                        HStack(alignment: .bottom, spacing: Spacing.md) {
                            Text("78")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.red)
                            Text("%")
                                .font(.title)
                                .foregroundColor(Color.text.secondary)
                                .padding(.bottom, 8)
                            Spacer()
                        }
                    }
                    
                    // Section 2: Icon + Title Only
                    sectionHeader("Icon + Title")
                    
                    StandardCard(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "Calories"
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("2,450")
                                .font(.system(size: 32, weight: .bold))
                            Text("Active: 850 cal")
                                .font(.subheadline)
                                .foregroundColor(Color.text.secondary)
                        }
                    }
                    
                    StandardCard(
                        icon: "figure.walk",
                        iconColor: .green,
                        title: "Steps"
                    ) {
                        HStack(alignment: .bottom, spacing: Spacing.sm) {
                            Text("8,432")
                                .font(.system(size: 32, weight: .bold))
                            Text("/ 10,000")
                                .font(.subheadline)
                                .foregroundColor(Color.text.secondary)
                                .padding(.bottom, 4)
                            Spacer()
                        }
                    }
                    
                    // Section 3: Title + Subtitle
                    sectionHeader("Title + Subtitle")
                    
                    StandardCard(
                        title: "Sleep Quality",
                        subtitle: "Last night • 11:30 PM - 7:00 AM"
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text("7h 32m")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("92%")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                            Text("Deep sleep: 2h 15m")
                                .font(.caption)
                                .foregroundColor(Color.text.secondary)
                        }
                    }
                    
                    // Section 4: Content Only (No Header)
                    sectionHeader("Content Only")
                    
                    StandardCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Training Recommendation")
                                .font(.heading)
                            Text("Your recovery score is good. Consider a moderate intensity workout today.")
                                .font(.body)
                                .foregroundColor(Color.text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Section 5: Tappable Cards
                    sectionHeader("Tappable Cards")
                    
                    StandardCard(
                        title: "View All Activities",
                        showChevron: true,
                        onTap: { selectedCard = "All Activities" }
                    ) {
                        Text("12 activities this week")
                            .font(.body)
                            .foregroundColor(Color.text.secondary)
                    }
                    
                    StandardCard(
                        icon: "chart.xyaxis.line",
                        iconColor: .purple,
                        title: "Trends & Analytics",
                        showChevron: true,
                        onTap: { selectedCard = "Trends" }
                    ) {
                        Text("View your performance over time")
                            .font(.body)
                            .foregroundColor(Color.text.secondary)
                    }
                    
                    // Section 6: Complex Content
                    sectionHeader("Complex Content")
                    
                    StandardCard(
                        icon: "bolt.fill",
                        iconColor: .yellow,
                        title: "Training Load",
                        subtitle: "Last 7 days"
                    ) {
                        VStack(spacing: Spacing.md) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("CTL")
                                        .font(.caption)
                                        .foregroundColor(Color.text.secondary)
                                    Text("45.2")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("ATL")
                                        .font(.caption)
                                        .foregroundColor(Color.text.secondary)
                                    Text("38.7")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("TSB")
                                        .font(.caption)
                                        .foregroundColor(Color.text.secondary)
                                    Text("+6.5")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Divider()
                            
                            Text("Form is good. Ready for intensity.")
                                .font(.caption)
                                .foregroundColor(Color.text.secondary)
                        }
                    }
                    
                    // Spacer at bottom
                    Color.clear.frame(height: 20)
                }
                .padding(.vertical)
            }
            .background(Color.background.primary)
            .navigationTitle("StandardCard Debug")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Card Tapped", isPresented: .constant(!selectedCard.isEmpty)) {
            Button("OK") { selectedCard = "" }
        } message: {
            Text("You tapped: \(selectedCard)")
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.text.primary)
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.sm)
    }
    
    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(Color.text.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(Color.text.primary)
        }
    }
}

#Preview {
    StandardCardDebugView()
}

#Preview("Dark Mode") {
    StandardCardDebugView()
        .preferredColorScheme(.dark)
}
