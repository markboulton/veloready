import SwiftUI

/// View displaying AI-generated daily brief (Pro) or computed brief (Free)
struct AIBriefView: View {
    @ObservedObject var service = AIBriefService.shared
    @ObservedObject var mlService = MLTrainingDataService.shared
    @ObservedObject var proConfig = ProFeatureConfig.shared
    @ObservedObject var recoveryScoreService = RecoveryScoreService.shared
    @ObservedObject var strainScoreService = StrainScoreService.shared
    @ObservedObject var profileManager = AthleteProfileManager.shared
    @ObservedObject private var scoresCoordinator = ServiceContainer.shared.scoresCoordinator // Single source of truth
    @State private var showingMLInfoSheet = false
    @State private var showingUpgradeSheet = false
    
    var body: some View {
        StandardCard(
            icon: Icons.System.sparkles,
            iconColor: ColorPalette.aiIconColor, // Orange - start of gradient
            title: proConfig.hasProAccess ? TodayContent.AIBrief.title : DailyBriefContent.title,
            useRainbowGradient: true // Only applies to title, not icon
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
                    // Show error with retry option - fall back to computed brief
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ErrorView(error: error) {
                            Task {
                                await service.fetchBrief(bypassCache: true)
                            }
                        }

                        // Show computed brief as fallback (honest, not parading as AI)
                        Divider()
                            .padding(.vertical, 4)

                        Text("Recovery-based guidance:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Text(generateBriefText())
                            .bodyStyle()
                            .fixedSize(horizontal: false, vertical: true)

                        TrainingMetricsView()
                    }
                } else if let text = service.briefText {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(text)
                            .bodyStyle()
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil) // Remove any line limits to prevent truncation
                        
                        // ML Data Collection Progress
                        // Show progress bar while collecting data (< 30 days)
                        // Show full-width analysis indicator when threshold met (>= 30 days)
                        if mlService.trainingDataCount > 0 {
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
            // Fetch brief on appear - WAIT for fresh scores before displaying
            // CRITICAL: AI Brief should be based on TODAY's scores, not cached from yesterday
            Logger.debug("🤖 [AI Brief] AIBriefView.onAppear - briefText: \(service.briefText == nil ? "nil" : "exists"), isLoading: \(service.isLoading)")
            Logger.debug("🤖 [AI Brief] ScoresCoordinator phase: \(scoresCoordinator.state.phase)")
            
            // Don't load brief until scores are ready
            // This prevents showing stale cached brief while scores are calculating
            if !service.isLoading {
                Logger.debug("🤖 [AI Brief] Triggering fetchBrief() from onAppear (will wait for scores)")
                Task {
                    // CRITICAL: Wait for ScoresCoordinator to be ready
                    // This ensures AI Brief is based on TODAY's scores, not yesterday's
                    var attempts = 0
                    while scoresCoordinator.state.phase != .ready && attempts < 200 {
                        if attempts % 20 == 0 { // Log every 2 seconds
                            Logger.debug("⏳ [AI Brief] Waiting for scores... phase: \(scoresCoordinator.state.phase) (attempt \(attempts + 1)/200)")
                        }
                        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                        attempts += 1
                    }
                    
                    if scoresCoordinator.state.phase == .ready {
                        let recovery = scoresCoordinator.state.recovery?.score ?? -1
                        let sleep = scoresCoordinator.state.sleep?.score ?? -1
                        let strain = scoresCoordinator.state.strain?.score ?? -1
                        Logger.info("✅ [AI Brief] All scores ready (R=\(recovery), S=\(sleep), St=\(strain)) - fetching brief")
                        
                        // Now fetch brief - will use today's cached brief if available, or generate new one
                        await service.fetchBrief()
                    } else {
                        Logger.warning("⚠️ [AI Brief] Timeout waiting for scores - phase: \(scoresCoordinator.state.phase)")
                        // Show a helpful error message instead of infinite spinner
                        await service.setErrorMessage("Scores are still calculating. Pull to refresh to try again.")
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
        // Use ScoresCoordinator as single source of truth (Phase 3 fix)
        // This ensures we always use the latest calculated score, not cached
        guard let recoveryScore = scoresCoordinator.state.recovery else {
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
    let retryAction: () -> Void
    @State private var showDebugInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: Icons.Status.warningFill)
                    .foregroundColor(.orange)
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Retry button
            Button(action: {
                HapticFeedback.light()
                retryAction()
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: Icons.Arrow.clockwise)
                        .font(.caption)
                    Text("Retry")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(ColorScale.blueAccent)
            }
            .buttonStyle(.plain)

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
    
    private var daysRemaining: Int {
        max(0, totalDays - currentDays)
    }
    
    private var progress: Double {
        min(1.0, Double(currentDays) / Double(totalDays))
    }
    
    // Calculate confidence percentage based on data quality
    // As we collect more days, confidence increases
    private var confidencePercentage: Int {
        // Start at 60% when we hit 30 days
        // Increase by ~0.5% per additional day
        // Cap at 95% (ML predictions always have some uncertainty)
        let baseConfidence = 60
        let additionalDays = currentDays - totalDays
        let bonusConfidence = additionalDays / 2
        return min(95, baseConfidence + bonusConfidence)
    }
    
    private var isAnalyzing: Bool {
        currentDays >= totalDays
    }
    
    /// RAG status color based on confidence
    private var ragStatusColor: Color {
        switch confidencePercentage {
        case 0..<60:
            return ColorScale.redAccent  // Red: < 60%
        case 60..<80:
            return ColorScale.amberAccent  // Amber: 60-79%
        default:
            return ColorScale.greenAccent  // Green: 80%+
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Text with info button on the right
            HStack(spacing: Spacing.sm) {
                if isAnalyzing {
                    // Analysis mode: Show label + confidence % (right-aligned) + up arrow
                    Text(TodayContent.AIBrief.mlAnalyzing)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: Icons.Arrow.upRight)
                            .font(.caption2)
                            .foregroundColor(ragStatusColor)
                        
                        Text("\(confidencePercentage)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(ragStatusColor)
                    }
                } else {
                    // Collection mode: Show label on left, days remaining on right
                    Text(TodayContent.AIBrief.mlCollecting)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(daysRemaining) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
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
            
            // Progress bar with AI rainbow gradient
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background (light grey)
                    Rectangle()
                        .fill(ColorPalette.neutral200)
                        .frame(height: 3)

                    // Progress fill with AI rainbow gradient
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: ColorPalette.aiGradientColors),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
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
