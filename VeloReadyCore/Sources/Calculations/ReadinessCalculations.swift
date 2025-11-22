import Foundation

/// Pure calculation logic for HRV-guided training readiness
/// Research-backed recommendations based on HRV trend, CV, and recovery metrics
/// Reference: PMC 8507742 - HRV-guided training meta-analysis
public struct ReadinessCalculations {

    // MARK: - Training Recommendation Categories

    /// Daily training recommendation based on readiness signals
    public enum TrainingRecommendation: String, CaseIterable {
        case trainHard = "Train Hard"
        case trainModerate = "Train Moderate"
        case trainEasy = "Train Easy"
        case rest = "Rest"

        /// Description for UI display
        public var description: String {
            switch self {
            case .trainHard:
                return "Your body is primed for a challenging workout. High-intensity or long sessions are appropriate."
            case .trainModerate:
                return "Good conditions for a standard training day. Moderate intensity recommended."
            case .trainEasy:
                return "Some fatigue signals detected. Keep intensity low and focus on technique or active recovery."
            case .rest:
                return "Multiple fatigue indicators suggest rest is needed. Consider a complete rest day or very light activity."
            }
        }

        /// Suggested TSS range for this recommendation
        public var suggestedTSSRange: ClosedRange<Int> {
            switch self {
            case .trainHard: return 100...200
            case .trainModerate: return 50...100
            case .trainEasy: return 20...50
            case .rest: return 0...20
            }
        }

        /// Suggested intensity factor (IF) for this recommendation
        public var suggestedIF: Double {
            switch self {
            case .trainHard: return 0.85
            case .trainModerate: return 0.70
            case .trainEasy: return 0.55
            case .rest: return 0.40
            }
        }
    }

    // MARK: - Readiness Result

    /// Complete readiness assessment result
    public struct ReadinessResult {
        /// Primary training recommendation
        public let recommendation: TrainingRecommendation
        /// Confidence in the recommendation (0-100%)
        public let confidence: Int
        /// Individual factor scores for transparency
        public let factors: ReadinessFactors
        /// Reasoning for the recommendation
        public let reasoning: [String]

        public init(recommendation: TrainingRecommendation, confidence: Int,
                    factors: ReadinessFactors, reasoning: [String]) {
            self.recommendation = recommendation
            self.confidence = confidence
            self.factors = factors
            self.reasoning = reasoning
        }
    }

    /// Individual readiness factors for UI breakdown
    public struct ReadinessFactors {
        /// HRV trend signal (-100 to +100, positive = improving)
        public let hrvTrendSignal: Int
        /// HRV stability signal based on CV (-100 to +100, positive = stable)
        public let hrvStabilitySignal: Int
        /// Recovery score signal (0-100)
        public let recoverySignal: Int
        /// Form/TSB signal (-100 to +100, positive = fresh)
        public let formSignal: Int

        public init(hrvTrendSignal: Int, hrvStabilitySignal: Int,
                    recoverySignal: Int, formSignal: Int) {
            self.hrvTrendSignal = hrvTrendSignal
            self.hrvStabilitySignal = hrvStabilitySignal
            self.recoverySignal = recoverySignal
            self.formSignal = formSignal
        }
    }

    // MARK: - Input Structure

    /// Inputs for readiness calculation
    public struct ReadinessInputs {
        /// 7-day rolling HRV average
        public let rollingHRV: Double?
        /// 30-day HRV baseline
        public let hrvBaseline: Double?
        /// HRV Coefficient of Variation (%)
        public let hrvCV: Double?
        /// Recovery score (0-100)
        public let recoveryScore: Int?
        /// TSB (Training Stress Balance / Form)
        public let tsb: Double?
        /// Yesterday's TSS
        public let yesterdayTSS: Double?
        /// Sleep score (0-100)
        public let sleepScore: Int?
        /// Days since last hard workout (TSS > 100)
        public let daysSinceHardWorkout: Int?

        public init(rollingHRV: Double? = nil, hrvBaseline: Double? = nil, hrvCV: Double? = nil,
                    recoveryScore: Int? = nil, tsb: Double? = nil, yesterdayTSS: Double? = nil,
                    sleepScore: Int? = nil, daysSinceHardWorkout: Int? = nil) {
            self.rollingHRV = rollingHRV
            self.hrvBaseline = hrvBaseline
            self.hrvCV = hrvCV
            self.recoveryScore = recoveryScore
            self.tsb = tsb
            self.yesterdayTSS = yesterdayTSS
            self.sleepScore = sleepScore
            self.daysSinceHardWorkout = daysSinceHardWorkout
        }
    }

    // MARK: - Main Readiness Calculation

    /// Calculate daily training readiness based on HRV-guided protocol
    /// Research: Athletes using HRV-guided training showed greater improvements
    /// vs prescribed training (PMC 8507742)
    ///
    /// - Parameter inputs: Readiness calculation inputs
    /// - Returns: ReadinessResult with recommendation, confidence, and reasoning
    public static func calculateReadiness(inputs: ReadinessInputs) -> ReadinessResult {
        var reasoning: [String] = []
        var dataQuality = 0 // Track how much data we have

        // Calculate individual signals
        let hrvTrendSignal = calculateHRVTrendSignal(
            rollingHRV: inputs.rollingHRV,
            baseline: inputs.hrvBaseline
        )
        if hrvTrendSignal != 0 { dataQuality += 25 }

        let hrvStabilitySignal = calculateHRVStabilitySignal(cv: inputs.hrvCV)
        if hrvStabilitySignal != 0 { dataQuality += 25 }

        let recoverySignal = inputs.recoveryScore ?? 50
        if inputs.recoveryScore != nil { dataQuality += 25 }

        let formSignal = calculateFormSignal(tsb: inputs.tsb)
        if inputs.tsb != nil { dataQuality += 25 }

        // Create factors struct
        let factors = ReadinessFactors(
            hrvTrendSignal: hrvTrendSignal,
            hrvStabilitySignal: hrvStabilitySignal,
            recoverySignal: recoverySignal,
            formSignal: formSignal
        )

        // Decision logic based on research-backed thresholds
        let recommendation: TrainingRecommendation

        // Primary signals: HRV trend + CV
        let hrvPositive = hrvTrendSignal > 5
        let hrvNegative = hrvTrendSignal < -10
        let cvLow = hrvStabilitySignal > 50     // CV < 5%
        let cvModerate = hrvStabilitySignal > 0  // CV < 10%
        let cvHigh = hrvStabilitySignal < -20   // CV > 15%
        let recovered = recoverySignal >= 70
        let fatigued = recoverySignal < 50
        let fresh = formSignal > 20
        let overreached = formSignal < -20

        // Decision tree based on HRV-guided training research
        if hrvNegative || cvHigh || overreached {
            // Clear fatigue signals - rest
            recommendation = .rest
            if hrvNegative { reasoning.append("HRV is \(abs(hrvTrendSignal))% below baseline") }
            if cvHigh { reasoning.append("HRV variability is high (CV > 15%)") }
            if overreached { reasoning.append("Training load indicates functional overreaching") }
        } else if fatigued && !fresh {
            // Moderate fatigue signals - easy day
            recommendation = .trainEasy
            if fatigued { reasoning.append("Recovery score is below 50%") }
            reasoning.append("Recommend low-intensity activity")
        } else if hrvPositive && cvLow && recovered {
            // All systems go - train hard
            recommendation = .trainHard
            reasoning.append("HRV is \(hrvTrendSignal)% above baseline")
            reasoning.append("Excellent HRV stability (CV < 5%)")
            reasoning.append("Recovery score is \(recoverySignal)%")
        } else if hrvPositive && cvModerate && recoverySignal >= 60 {
            // Good signals - moderate training OK
            recommendation = .trainModerate
            reasoning.append("HRV trend is positive")
            reasoning.append("Recovery is adequate (\(recoverySignal)%)")
        } else if recovered && fresh {
            // Recovery good but HRV data limited - moderate
            recommendation = .trainModerate
            reasoning.append("Recovery and form are good")
            if inputs.rollingHRV == nil {
                reasoning.append("Limited HRV data - moderate recommendation")
            }
        } else {
            // Mixed signals or insufficient data - default to easy
            recommendation = .trainEasy
            reasoning.append("Mixed readiness signals detected")
            reasoning.append("Conservative approach recommended")
        }

        // Calculate confidence based on data quality and signal clarity
        let signalClarity = calculateSignalClarity(factors: factors)
        let confidence = min(100, (dataQuality + signalClarity) / 2)

        if dataQuality < 50 {
            reasoning.append("Note: Limited data available - confidence reduced")
        }

        return ReadinessResult(
            recommendation: recommendation,
            confidence: confidence,
            factors: factors,
            reasoning: reasoning
        )
    }

    // MARK: - Signal Calculations

    /// Calculate HRV trend signal from rolling average vs baseline
    /// - Returns: Signal from -100 (declining) to +100 (improving)
    private static func calculateHRVTrendSignal(rollingHRV: Double?, baseline: Double?) -> Int {
        guard let rolling = rollingHRV, let base = baseline, base > 0 else {
            return 0
        }

        let percentChange = ((rolling - base) / base) * 100

        // Scale to -100 to +100
        // ±20% change maps to ±100
        return Int(max(-100, min(100, percentChange * 5)))
    }

    /// Calculate HRV stability signal from CV
    /// - Returns: Signal from -100 (unstable) to +100 (very stable)
    private static func calculateHRVStabilitySignal(cv: Double?) -> Int {
        guard let cv = cv else { return 0 }

        // Research thresholds:
        // CV < 5% = excellent stability (+100)
        // CV 5-10% = good stability (+50)
        // CV 10-15% = moderate (-25)
        // CV > 15% = poor stability (-100)

        if cv < 5.0 {
            return Int(100 - (cv * 10))  // 0-50 range for CV 0-5%
        } else if cv < 10.0 {
            return Int(50 - ((cv - 5) * 10))  // 50 to 0 for CV 5-10%
        } else if cv < 15.0 {
            return Int(-((cv - 10) * 10))  // 0 to -50 for CV 10-15%
        } else {
            return Int(max(-100, -50 - ((cv - 15) * 10)))  // -50 to -100 for CV > 15%
        }
    }

    /// Calculate form signal from TSB
    /// - Returns: Signal from -100 (overreached) to +100 (very fresh)
    private static func calculateFormSignal(tsb: Double?) -> Int {
        guard let tsb = tsb else { return 0 }

        // TSB interpretation:
        // +25 to +35 = peak freshness
        // +5 to +25 = fresh, ready to race
        // -10 to +5 = neutral
        // -25 to -10 = fatigued
        // < -25 = overreached

        // Scale TSB to -100 to +100
        // TSB range typically -40 to +40
        return Int(max(-100, min(100, tsb * 2.5)))
    }

    /// Calculate signal clarity (how clear/consistent the signals are)
    /// - Returns: Clarity score 0-100
    private static func calculateSignalClarity(factors: ReadinessFactors) -> Int {
        // Check if signals agree
        let signals = [
            factors.hrvTrendSignal,
            factors.hrvStabilitySignal,
            factors.recoverySignal - 50,  // Center around 0
            factors.formSignal
        ]

        // Count positive vs negative signals
        let positive = signals.filter { $0 > 10 }.count
        let negative = signals.filter { $0 < -10 }.count
        let neutral = signals.count - positive - negative

        // High clarity if signals mostly agree
        if positive >= 3 || negative >= 3 {
            return 80 + (neutral * 5)  // Clear direction
        } else if positive == 0 && negative == 0 {
            return 60  // All neutral - moderate clarity
        } else {
            return 40  // Mixed signals - low clarity
        }
    }

    // MARK: - Quick Assessment

    /// Quick readiness check based on minimal data
    /// Use when full data isn't available
    public static func quickReadiness(
        recoveryScore: Int,
        yesterdayTSS: Double? = nil
    ) -> TrainingRecommendation {
        let tssHigh = (yesterdayTSS ?? 0) > 150

        if recoveryScore >= 80 && !tssHigh {
            return .trainHard
        } else if recoveryScore >= 60 {
            return .trainModerate
        } else if recoveryScore >= 40 {
            return .trainEasy
        } else {
            return .rest
        }
    }
}
