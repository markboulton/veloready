import SwiftUI

/// View displaying AI-generated daily brief
struct AIBriefView: View {
    @ObservedObject var service = AIBriefService.shared
    @ObservedObject var mlService = MLTrainingDataService.shared
    @State private var showingMLInfoSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Custom header with rainbow gradient (StandardCard doesn't support this)
            HStack(spacing: 8) {
                Image(systemName: Icons.System.sparkles)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(TodayContent.AIBrief.title)
                    .font(.heading)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.bottom, Spacing.md)
            
            // Content with fixed height to prevent layout shifts
            ZStack(alignment: .topLeading) {
                // Invisible placeholder to maintain height
                Text(CommonContent.Preview.placeholderText)
                    .bodyStyle()
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0)
                
                // Actual content
                if service.isLoading {
                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(TodayContent.AIBrief.analyzing)
                            .bodyStyle()
                            .foregroundColor(.text.secondary)
                    }
                    .padding(.vertical, Spacing.md)
                } else if let error = service.error {
                    ErrorView(error: error)
                } else if let text = service.briefText {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(text)
                            .bodyStyle()
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // ML Data Collection Progress (if not sufficient data yet)
                        if mlService.trainingDataCount < 30 {
                            MLDataCollectionView(
                                currentDays: mlService.trainingDataCount,
                                totalDays: 30,
                                showInfoSheet: { showingMLInfoSheet = true }
                            )
                            .padding(.top, 4)
                        }
                        
                        // Training Metrics
                        TrainingMetricsView()
                    }
                } else {
                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(TodayContent.AIBrief.analyzing)
                            .bodyStyle()
                            .foregroundColor(.text.secondary)
                    }
                    .padding(.vertical, Spacing.md)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.08))
        )
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxl / 2)
            .onAppear {
            // Fetch brief on appear if not already loaded
            // Note: If sleep data is missing, the recovery refresh will trigger AI brief update
            if service.briefText == nil && !service.isLoading {
                Task {
                    await service.fetchBrief()
                }
            }
            
            // Refresh ML training data count to ensure progress bar updates
            Task {
                await mlService.refreshTrainingDataCount()
            }
        }
        .sheet(isPresented: $showingMLInfoSheet) {
            MLPersonalizationInfoSheet()
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
                Image(systemName: Icons.Status.warningFill)
                    .foregroundColor(.primary)
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            #if DEBUG
            Button(action: {
                showDebugInfo.toggle()
            }) {
                Text(showDebugInfo ? TodayContent.AIBrief.hideDebugInfo : TodayContent.AIBrief.showDebugInfo)
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

// MARK: - ML Data Collection View

private struct MLDataCollectionView: View {
    let currentDays: Int
    let totalDays: Int
    
    let showInfoSheet: () -> Void
    
    private var daysRemaining: Int {
        max(0, totalDays - currentDays)
    }
    
    private var progress: Double {
        Double(currentDays) / Double(totalDays)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Text with info button on the right
            HStack {
                Text(TodayContent.AIBrief.mlCollecting)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: showInfoSheet) {
                    Image(systemName: Icons.Status.info)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Progress bar (similar to chart progress bars)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background (grey)
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress (white)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text("\(currentDays) days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(daysRemaining) \(TodayContent.AIBrief.mlDaysRemaining)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Training Metrics View

struct TrainingMetricsView: View {
    @ObservedObject private var recoveryService = RecoveryScoreService.shared
    @ObservedObject private var wellnessService = WellnessDetectionService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Grey dividing line before TSB section
            Divider()
                .padding(.vertical, 4)
            
            // TSB (Training Stress Balance)
            if let recovery = recoveryService.currentRecoveryScore {
                // Use actual CTL/ATL if available, otherwise use defaults
                let ctl = recovery.inputs.ctl ?? 50.0
                let atl = recovery.inputs.atl ?? 45.0
                let tsb = ctl - atl
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: Icons.DataSource.intervalsICU)
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
                                .foregroundColor(.white)
                        }
                        
                        Text(descriptionForTSB(tsb))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            // Target TSS Range
            if let recovery = recoveryService.currentRecoveryScore {
                // Use actual CTL if available, otherwise use default
                let ctl = recovery.inputs.ctl ?? 50.0
                let tssLow = Int(ctl * 0.8)
                let tssHigh = Int(ctl * 1.5)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: Icons.System.target)
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
                                .foregroundColor(.white)
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
