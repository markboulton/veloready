import SwiftUI

/// View displaying AI-generated daily brief (Pro) or computed brief (Free)
struct AIBriefView: View {
    @ObservedObject var service = AIBriefService.shared
    @ObservedObject var mlService = MLTrainingDataService.shared
    @ObservedObject var proConfig = ProFeatureConfig.shared
    @ObservedObject var recoveryScoreService = RecoveryScoreService.shared
    @ObservedObject var strainScoreService = StrainScoreService.shared
    @ObservedObject var profileManager = AthleteProfileManager.shared
    @State private var showingMLInfoSheet = false
    @State private var showingUpgradeSheet = false
    
    var body: some View {
        StandardCard(
            icon: Icons.System.sparkles,
            title: proConfig.hasProAccess ? TodayContent.AIBrief.title : DailyBriefContent.title
        ) {
            if proConfig.hasProAccess {
                proContent
            } else {
                freeContent
            }
        }
        .sheet(isPresented: $showingMLInfoSheet) {
            MLPersonalizationInfoSheet()
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            PaywallView()
        }
        .task {
            // Refresh ML training data count on appear
            await mlService.refreshTrainingDataCount()
        }
    }
    
    // MARK: - Pro Content
    
    private var proContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            
            ZStack(alignment: .topLeading) {
                Text(CommonContent.Preview.placeholderText)
                    .bodyStyle()
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0)
                
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
                    VStack(alignment: .leading, spacing: Spacing.md) {
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
                            .padding(.top, Spacing.xs)
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
        .onAppear {
            // Fetch brief on appear if not already loaded
            // CRITICAL: Wait for recovery score to be available (race condition fix)
            Logger.debug("🤖 [AI Brief] AIBriefView.onAppear - briefText: \(service.briefText == nil ? "nil" : "exists"), isLoading: \(service.isLoading)")
            if service.briefText == nil && !service.isLoading {
                Logger.debug("🤖 [AI Brief] Triggering fetchBrief() from onAppear")
                Task {
                    // Wait for recovery score to be calculated (max 10s)
                    var attempts = 0
                    while RecoveryScoreService.shared.currentRecoveryScore == nil && attempts < 100 {
                        Logger.debug("⏳ [AI Brief] Waiting for recovery score... (attempt \(attempts + 1))")
                        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                        attempts += 1
                    }
                    
                    if RecoveryScoreService.shared.currentRecoveryScore != nil {
                        Logger.debug("✅ [AI Brief] Recovery score ready - fetching brief")
                        await service.fetchBrief()
                    } else {
                        Logger.warning("⚠️ [AI Brief] Timeout waiting for recovery score")
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .todayDataRefreshed)) { _ in
            // Refresh ML training data count when Today data refreshes
            Task {
                await mlService.refreshTrainingDataCount()
            }
        }
    }
    
    // MARK: - Free Content
    
    private var freeContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(generateBriefText())
                .bodyStyle()
                .fixedSize(horizontal: false, vertical: true)
            
            TrainingMetricsView()
            
            Button(action: {
                showingUpgradeSheet = true
            }) {
                Text(DailyBriefContent.upgradePrompt)
                    .font(.subheadline)
                    .foregroundColor(ColorScale.blueAccent)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Free Brief Generation
    
    private func generateBriefText() -> String {
        guard let recoveryScore = recoveryScoreService.currentRecoveryScore else {
            return "Calculating your daily brief..."
        }
        
        var brief = recoveryMessage(recoveryScore.score)
        
        if let ctl = recoveryScore.inputs.ctl,
           let atl = recoveryScore.inputs.atl {
            let tsb = ctl - atl
            brief += " Your training stress balance is \(tsbLabel(tsb).lowercased()) (\(String(format: "%.0f", tsb))). "
        }
        
        brief += trainingRecommendation(recoveryScore.score) + "."
        
        return brief
    }
    
    private func recoveryMessage(_ score: Int) -> String {
        if score >= 80 {
            return DailyBriefContent.Recovery.optimal
        } else if score >= 60 {
            return DailyBriefContent.Recovery.moderate
        } else {
            return DailyBriefContent.Recovery.low
        }
    }
    
    private func tsbLabel(_ tsb: Double) -> String {
        if tsb < -10 {
            return DailyBriefContent.TSB.fatigued
        } else if tsb < 5 {
            return DailyBriefContent.TSB.optimal
        } else if tsb < 15 {
            return DailyBriefContent.TSB.fresh
        } else {
            return DailyBriefContent.TSB.veryFresh
        }
    }
    
    private func trainingRecommendation(_ recoveryScore: Int) -> String {
        if recoveryScore >= 80 {
            return DailyBriefContent.TrainingRecommendation.highIntensity
        } else if recoveryScore >= 60 {
            return DailyBriefContent.TrainingRecommendation.moderate
        } else {
            return DailyBriefContent.TrainingRecommendation.easy
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let error: AIBriefError
    @State private var showDebugInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
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
                    .background(ColorPalette.neutral200)
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
    
    @State private var animatedProgress: Double = 0.0
    
    private var daysRemaining: Int {
        max(0, totalDays - currentDays)
    }
    
    private var progress: Double {
        Double(currentDays) / Double(totalDays)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Text with info button on the right
            HStack {
                Text(TodayContent.AIBrief.mlCollecting)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.light()
                    showInfoSheet()
                }) {
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
                        .fill(ColorPalette.neutral200)
                        .frame(height: 2)
                    
                    // Progress (blue) - animates from left
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * animatedProgress, height: 2)
                }
            }
            .frame(height: 2)
            .onScrollAppear {
                // Animate progress bar from left - faster speed
                withAnimation(.easeOut(duration: 0.65)) {
                    animatedProgress = progress
                }
            }
            
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
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Grey dividing line before TSB section
            Divider()
                .padding(.vertical, 4)
            
            // TSB (Training Stress Balance)
            if let recovery = recoveryService.currentRecoveryScore {
                // Use actual CTL/ATL if available, otherwise use defaults
                let ctl = recovery.inputs.ctl ?? 50.0
                let atl = recovery.inputs.atl ?? 45.0
                let tsb = ctl - atl
                
                HStack(alignment: .top, spacing: Spacing.sm) {
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
                                .foregroundColor(Color.text.primary)
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
                
                HStack(alignment: .top, spacing: Spacing.sm) {
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
                                .foregroundColor(Color.text.primary)
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
