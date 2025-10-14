import SwiftUI

/// Specialized Pro upgrade card for ride detail page
/// Combines AI Analysis, Training Load, and Intensity features into one CTA
struct RideDetailProCard: View {
    @State private var showPaywall = false
    @State private var showLearnMore = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: { showPaywall = true }) {
            VStack(alignment: .leading, spacing: 20) {
                // Header with title and PRO badge
                HStack(spacing: 8) {
                    Text("Unlock Advanced Ride Analytics")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(invertedTextColor)
                    
                    Text("PRO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.button.primary)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                // Learn More link
                Button(action: {
                    showLearnMore = true
                }) {
                    Text("Learn more")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.button.primary)
                }
                
                // Three feature bullets
                VStack(alignment: .leading, spacing: 16) {
                    FeatureBullet(
                        icon: "sparkles",
                        title: "AI Ride Analysis",
                        description: "Get intelligent insights and personalized recommendations for every ride"
                    )
                    
                    FeatureBullet(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Training Load Tracking",
                        description: "Monitor your fitness, fatigue, and form with 37-day CTL/ATL/TSB trends"
                    )
                    
                    FeatureBullet(
                        icon: "gauge.high",
                        title: "Intensity Breakdown",
                        description: "Analyze effort distribution and intensity factor for optimal training"
                    )
                }
                
                // Upgrade button
                HStack {
                    Spacer()
                    
                    Text("Upgrade to Pro")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.button.primary)
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(invertedBackgroundColor)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showLearnMore) {
            LearnMoreSheet(content: .advancedRideAnalytics, isPresented: $showLearnMore)
        }
    }
    
    // MARK: - Colors
    
    private var invertedBackgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var invertedTextColor: Color {
        colorScheme == .dark ? .black : .white
    }
}

// MARK: - Feature Bullet

private struct FeatureBullet: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.button.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(invertedTextColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(invertedTextColor.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var invertedTextColor: Color {
        colorScheme == .dark ? .black : .white
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    RideDetailProCard()
        .padding()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    RideDetailProCard()
        .padding()
        .preferredColorScheme(.dark)
}
