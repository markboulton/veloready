import SwiftUI

/// Rainbow gradient modifier for AI text and icons
struct RainbowGradient: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        ColorPalette.pink,
                        ColorPalette.purple,
                        ColorPalette.blue,
                        ColorPalette.cyan,
                        ColorPalette.mint,
                        ColorPalette.yellow,
                        ColorPalette.peach
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .mask(content)
    }
}

extension View {
    func rainbowGradient() -> some View {
        modifier(RainbowGradient())
    }
}

/// View displaying AI-generated daily brief
struct AIBriefView: View {
    @ObservedObject var service = AIBriefService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                // Header with rainbow gradient
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.heading)
                        .rainbowGradient()
                    
                    Text(TodayContent.AIBrief.title)
                        .font(.heading)
                        .rainbowGradient()
                    
                    Spacer()
                }
                .padding(.bottom, 12)
                
                // Content
                if service.isLoading {
                    LoadingStateView(size: .small)
                        .padding(.vertical, 8)
                } else if let error = service.error {
                    ErrorView(error: error)
                } else if let text = service.briefText {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(text)
                            .bodyStyle()
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Training Metrics
                        TrainingMetricsView()
                    }
                } else {
                    LoadingStateView(size: .small)
                        .padding(.vertical, 8)
                }
                
                SectionDivider(bottomPadding: 0)
            }
            .onAppear {
            // Fetch brief on appear if not already loaded
            // Note: If sleep data is missing, the recovery refresh will trigger AI brief update
            if service.briefText == nil && !service.isLoading {
                Task {
                    await service.fetchBrief()
                }
            }
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let error: AIBriefError
    @State private var showDebugInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.primary)
                Text(error.localizedDescription ?? "Unknown error")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            #if DEBUG
            Button(action: {
                showDebugInfo.toggle()
            }) {
                Text(showDebugInfo ? "Hide Debug Info" : "Show Debug Info")
                    .font(.caption)
                    .foregroundColor(Color.button.primary)
            }
            
            if showDebugInfo {
                Text(error.debugHint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            #endif
        }
    }
}

// MARK: - Training Metrics View

private struct TrainingMetricsView: View {
    @ObservedObject private var recoveryService = RecoveryScoreService.shared
    @ObservedObject private var wellnessService = WellnessDetectionService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            // TSB (Training Stress Balance)
            if let recovery = recoveryService.currentRecoveryScore,
               let ctl = recovery.inputs.ctl,
               let atl = recovery.inputs.atl {
                let tsb = ctl - atl
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(TodayContent.AIBrief.tsb)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "%.1f", tsb))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(colorForTSB(tsb))
                        }
                        
                        Text(descriptionForTSB(tsb))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            // Target TSS Range
            if let recovery = recoveryService.currentRecoveryScore,
               let ctl = recovery.inputs.ctl {
                let tssLow = Int(ctl * 0.8)
                let tssHigh = Int(ctl * 1.5)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(TodayContent.AIBrief.targetTSS)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("\(tssLow)-\(tssHigh)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.semantic.success)
                        }
                        
                        Text(TodayContent.AIBrief.tssDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
    
    private func colorForTSB(_ tsb: Double) -> Color {
        // Override color if wellness alert is present
        if let alert = wellnessService.currentAlert {
            return alert.severity.color // Use alert color
        }
        
        // Override color if recovery is poor (regardless of TSB)
        if let recovery = recoveryService.currentRecoveryScore {
            if recovery.score < 70 {
                return .orange // Fatigued - recovery is poor
            }
        }
        
        switch tsb {
        case ..<(-30):
            return .red // Very fatigued
        case -30..<(-10):
            return .orange // Fatigued
        case -10..<5:
            return .yellow // Optimal training zone
        case 5..<25:
            return .green // Fresh - good for hard training
        default:
            return .blue // Very fresh - may be losing fitness
        }
    }
    
    private func descriptionForTSB(_ tsb: Double) -> String {
        // Override description if wellness alert is present
        if let alert = wellnessService.currentAlert {
            switch alert.severity {
            case .red:
                return "Health concerns detected - prioritize recovery"
            case .amber:
                return "Multiple metrics elevated - consider rest day"
            case .yellow:
                return "Some unusual patterns - monitor closely"
            }
        }
        
        // Override description if recovery is poor (regardless of TSB)
        if let recovery = recoveryService.currentRecoveryScore {
            if recovery.score < 70 {
                return "Recovery is poor - prioritize rest"
            }
        }
        
        switch tsb {
        case ..<(-30):
            return "Very fatigued - prioritize recovery"
        case -30..<(-10):
            return "Fatigued - consider easier training"
        case -10..<5:
            return "Optimal training zone - balanced load"
        case 5..<25:
            return "Fresh and ready - good for hard efforts"
        default:
            return "Very fresh - consider increasing training load"
        }
    }
}

// MARK: - Preview

struct AIBriefView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Loading state
            AIBriefView()
            
            // Success state
            AIBriefView()
            
            // Error state
            AIBriefView()
        }
        .padding()
    }
}
