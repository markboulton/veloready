import SwiftUI

/// View displaying AI-generated ride summary (PRO feature)
struct RideSummaryView: View {
    let activity: IntervalsActivity
    @ObservedObject var service = RideSummaryService.shared
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @State private var hasLoaded = false
    
    var body: some View {
        // Only show for PRO users
        guard proConfig.hasProAccess else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with rainbow gradient
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.heading)
                            .foregroundColor(ColorPalette.pink)
                        
                        Text(RideSummaryContent.title)
                            .font(.heading)
                            .rainbowGradient()
                        
                        Spacer()
                    }
                    
                    // Content
                    if service.isLoading {
                        LoadingView()
                    } else if let error = service.error {
                        ErrorView(error: error, activity: activity)
                    } else if let summary = service.currentSummary {
                        SummaryContentView(summary: summary)
                    } else {
                        Text(RideSummaryContent.loading)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .onAppear {
                    // Fetch summary on appear if not already loaded
                    if !hasLoaded && service.currentSummary == nil && !service.isLoading {
                        hasLoaded = true
                        Task {
                            await service.fetchSummary(for: activity)
                        }
                    }
                }
                .onDisappear {
                    // Clear summary when leaving the screen
                    service.clearSummary()
                    hasLoaded = false
                }
            }
        )
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let error: RideSummaryError
    let activity: IntervalsActivity
    @ObservedObject var service = RideSummaryService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.primary)
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Retry button
            Button(action: {
                Task {
                    await service.fetchSummary(for: activity)
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.button.primary)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Summary Content View

private struct SummaryContentView: View {
    let summary: RideSummaryResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Headline (prominent)
            Text(summary.headline)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Execution score
            ExecutionScoreView(score: summary.executionScore)
            
            // Coach brief
            Text(summary.coachBrief)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Strengths & Limiters
            if !summary.strengths.isEmpty || !summary.limiters.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Strengths
                    if !summary.strengths.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.primary)
                                    .font(.caption)
                                Text(RideSummaryContent.strengths)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            ForEach(summary.strengths, id: \.self) { strength in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(strength)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    
                    // Limiters
                    if !summary.limiters.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.primary)
                                    .font(.caption)
                                Text(RideSummaryContent.areasToImprove)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            ForEach(summary.limiters, id: \.self) { limiter in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(limiter)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            }
            
            // Next hint
            if !summary.nextHint.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.primary)
                            .font(.caption)
                        Text(RideSummaryContent.nextSteps)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(summary.nextHint)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Execution Score View

private struct ExecutionScoreView: View {
    let score: Int
    
    private var scoreColor: Color {
        switch score {
        case 90...100:
            return ColorScale.greenAccent
        case 70..<90:
            return ColorScale.blueAccent
        case 50..<70:
            return ColorScale.amberAccent
        default:
            return ColorScale.redAccent
        }
    }
    
    private var scoreLabel: String {
        switch score {
        case 90...100:
            return RideSummaryContent.ExecutionScore.excellent
        case 70..<90:
            return RideSummaryContent.ExecutionScore.good
        case 50..<70:
            return RideSummaryContent.ExecutionScore.fair
        default:
            return RideSummaryContent.ExecutionScore.needsWork
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Circular gauge
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(RideSummaryContent.ExecutionScore.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(RideSummaryContent.ExecutionScore.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(scoreLabel)
                    .font(.caption)
                    .foregroundColor(scoreColor)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
// Preview disabled - test directly in app with real activities
