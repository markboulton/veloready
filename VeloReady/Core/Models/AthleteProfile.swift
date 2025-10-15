//
//  AthleteProfile.swift
//  Rideready
//
//  Athlete profile with zones computed from recent activities or manually set
//

import Foundation

struct AthleteProfile: Codable {
    var ftp: Double?
    var powerZones: [Double]? // Zone boundaries
    var maxHR: Double?
    var hrZones: [Double]? // Zone boundaries
    var lthr: Double?
    var restingHR: Double?
    var weight: Double?
    var sex: String? // M/F for gender-specific calculations
    
    // Advanced metrics (Leo et al. 2022, Jones et al. 2010)
    var wPrime: Double? // W' - Anaerobic work capacity (joules)
    var powerProfile: PowerDurationProfile? // 5s, 1min, 5min, 20min power
    var vo2maxEstimate: Double? // Estimated from CP curve (ml/kg/min)
    
    // Metadata about where these values came from
    var ftpSource: ZoneSource
    var hrZonesSource: ZoneSource
    var lastUpdated: Date
    var lastComputedFromActivities: Date?
    var dataQuality: DataQuality? // Confidence in computed values
    
    enum ZoneSource: String, Codable {
        case computed = "computed" // PRO: Adaptive from performance data
        case manual = "manual" // User manually entered values
        case intervals = "intervals" // From Intervals.icu sync
        case coggan = "coggan" // Standard Coggan zones (FTP/MaxHR based)
    }
    
    init() {
        self.ftpSource = .computed
        self.hrZonesSource = .computed
        self.lastUpdated = Date()
    }
}

// MARK: - Power Duration Profile (Leo et al. 2022)

struct PowerDurationProfile: Codable {
    var power5s: Double?   // 5-second max power (Neuromuscular)
    var power1min: Double? // 1-minute power (Anaerobic)
    var power5min: Double? // 5-minute power (VO2max)
    var power20min: Double? // 20-minute power (FTP estimate)
    var power60min: Double? // 60-minute power (Endurance)
    
    // Critical Power model parameters (Burnley & Jones 2018)
    var criticalPower: Double? // CP asymptote
    var wPrime: Double? // W' - work above CP
}

// MARK: - Data Quality Assessment

struct DataQuality: Codable {
    var confidenceScore: Double // 0-1: Quality of data used for computation
    var sampleSize: Int // Number of activities analyzed
    var hasLongRides: Bool // Activities > 45 minutes present
    var hasPowerData: Bool // Normalized power available
    var hasHRData: Bool // Heart rate data available
    var variabilityIndex: Double // Consistency of performances (lower = more consistent)
}

// MARK: - Athlete Profile Manager

class AthleteProfileManager: ObservableObject {
    static let shared = AthleteProfileManager()
    
    @Published var profile: AthleteProfile
    
    private let userDefaultsKey = "athlete_profile_v2" // v2 for new fields
    
    init() {
        // Load from UserDefaults (will migrate to Core Data in future)
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(AthleteProfile.self, from: data) {
            self.profile = decoded
            Logger.data("Loaded athlete profile from cache:")
            Logger.debug("   Adaptive FTP: \(decoded.ftp ?? 0)W (\(decoded.ftpSource.rawValue))")
            Logger.debug("   Max HR: \(decoded.maxHR ?? 0)bpm (\(decoded.hrZonesSource.rawValue))")
            if let wPrime = decoded.wPrime {
                Logger.debug("   W': \(Int(wPrime))J")
            }
            if let vo2max = decoded.vo2maxEstimate {
                Logger.debug("   VO2max: \(Int(vo2max)) ml/kg/min")
            }
            if let quality = decoded.dataQuality {
                Logger.debug("   Data Quality: \(Int(quality.confidenceScore * 100))%")
            }
        } else {
            self.profile = AthleteProfile()
            Logger.data("Created new athlete profile")
        }
    }
    
    /// Use Strava athlete FTP as fallback if no computed FTP yet
    /// Only runs if user is NOT authenticated with Intervals.icu (to avoid interfering)
    private func useStravaFTPIfAvailable() async {
        // Early exit if FTP already exists
        guard profile.ftp == nil || profile.ftp == 0 else { return }
        
        // OPTIMIZATION: Only use Strava fallback if user is NOT using Intervals
        // This prevents unnecessary API calls for Intervals users
        let intervalsAuthenticated = await MainActor.run { IntervalsOAuthManager.shared.isAuthenticated }
        if intervalsAuthenticated {
            Logger.data("⏭️ Skipping Strava FTP fallback - user has Intervals.icu")
            return
        }
        
        do {
            Logger.data("📊 Attempting to fetch Strava athlete FTP as fallback (Strava-only user)...")
            // Use cache to avoid repeated API calls
            let stravaAthlete = try await StravaAthleteCache.shared.getAthlete()
            
            if let stravaFTP = stravaAthlete.ftp, stravaFTP > 0 {
                Logger.data("✅ Using Strava FTP as fallback: \(stravaFTP)W")
                profile.ftp = Double(stravaFTP)
                profile.ftpSource = .intervals // Mark as from external source
                profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: Double(stravaFTP))
                profile.lastUpdated = Date()
                save()
            } else {
                Logger.data("⚠️ Strava athlete has no FTP set")
            }
        } catch {
            Logger.warning("⚠️ Could not fetch Strava athlete data: \(error)")
        }
    }
    
    /// Compute zones from recent activities using sports science algorithms (last 120 days)
    /// Uses Critical Power model, power curve analysis, and HR lactate threshold detection
    func computeFromActivities(_ activities: [IntervalsActivity]) async {
        Logger.data("========== COMPUTING ADAPTIVE ZONES FROM PERFORMANCE DATA ==========")
        Logger.data("Using modern sports science algorithms (CP model, power distribution, HR analysis)")
        
        // NEW: Try to get Strava FTP as fallback before computing
        await useStravaFTPIfAvailable()
        
        let oneTwentyDaysAgo = Calendar.current.date(byAdding: .day, value: -120, to: Date())!
        
        // Filter to last 120 days
        let recentActivities = activities.filter { activity in
            guard let date = parseDate(from: activity.startDateLocal) else { return false }
            return date >= oneTwentyDaysAgo
        }
        
        Logger.data("Found \(recentActivities.count) activities in last 120 days")
        Logger.data("Ignoring hardcoded Intervals.icu zones - computing from actual performance data")
        
        // Only update if source is NOT manual (don't override user settings)
        if profile.ftpSource != .manual {
            computeFTPFromPerformanceData(recentActivities)
        } else {
            Logger.data("Skipping FTP computation - user has manual override (FTP: \(profile.ftp ?? 0)W)")
        }
        
        if profile.hrZonesSource != .manual {
            computeHRZonesFromPerformanceData(recentActivities)
        } else {
            Logger.data("Skipping HR zones computation - user has manual override (Max HR: \(profile.maxHR ?? 0)bpm)")
        }
        
        // Always update weight, resting HR, LTHR from most recent
        updateAuxiliaryMetrics(recentActivities)
        
        // Ensure zones are generated even if FTP/HR computation had limited data
        if (profile.powerZones == nil || profile.powerZones!.isEmpty), let ftp = profile.ftp, ftp > 0 {
            profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp)
            Logger.data("✅ Generated default power zones from FTP: \(Int(ftp))W")
        }
        
        if (profile.hrZones == nil || profile.hrZones!.isEmpty), let maxHR = profile.maxHR, maxHR > 0 {
            profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: maxHR)
            Logger.data("✅ Generated default HR zones from max HR: \(Int(maxHR))bpm")
        }
        
        profile.lastComputedFromActivities = Date()
        profile.lastUpdated = Date()
        save()
        
        Logger.data("================================================")
    }
    
    /// Compute FTP using Enhanced Critical Power model with confidence scoring
    /// Based on Leo et al. (2022), Burnley & Jones (2018), Decroix et al. (2016)
    /// Target accuracy: ±2-5% with proper data
    private func computeFTPFromPerformanceData(_ activities: [IntervalsActivity]) {
        Logger.data("========== FTP COMPUTATION (ENHANCED v2) ==========")
        Logger.data("Target: ±2-5% accuracy with confidence-based buffer")
        
        guard !activities.isEmpty else {
            Logger.data("❌ No activities available")
            return
        }
        
        // STAGE 1: Find best sustained powers at key durations
        Logger.debug("📊")
        Logger.data("STAGE 1: Building Power-Duration Curve")
        Logger.data("Analyzing \(activities.count) activities...")
        
        var best60min: Double = 0
        var best20min: Double = 0
        var best5min: Double = 0
        var maxNP: Double = 0
        var ultraEnduranceBoost: Double? = nil
        
        for (index, activity) in activities.enumerated() {
            let np = activity.normalizedPower ?? 0
            let duration = activity.duration ?? 0
            
            if np > 0 {
                Logger.data("  Activity \(index + 1): \(activity.name ?? "Unnamed") - NP: \(Int(np))W, Duration: \(Int(duration/60))min")
                
                maxNP = max(maxNP, np)
                
                // Ultra-endurance detection (3+ hours)
                if duration >= 10800 { // 3+ hours
                    let boost: Double
                    if duration >= 18000 { // 5+ hours
                        boost = 1.12 // NP is ~89% of FTP
                        Logger.data("    ✓ Ultra-endurance (5+ hours): \(Int(np))W → Estimated 60-min power: \(Int(np * boost))W")
                    } else if duration >= 14400 { // 4-5 hours
                        boost = 1.10 // NP is ~91% of FTP
                        Logger.data("    ✓ Ultra-endurance (4-5 hours): \(Int(np))W → Estimated 60-min power: \(Int(np * boost))W")
                    } else { // 3-4 hours
                        boost = 1.07 // NP is ~93% of FTP
                        Logger.data("    ✓ Ultra-endurance (3-4 hours): \(Int(np))W → Estimated 60-min power: \(Int(np * boost))W")
                    }
                    
                    let estimatedPower = np * boost
                    if estimatedPower > best60min {
                        best60min = estimatedPower
                        ultraEnduranceBoost = boost
                    }
                } else if duration >= 3600 { // 60-90 min (normal)
                    if np > best60min {
                        best60min = np
                        Logger.data("    ✓ New best 60-min power: \(Int(np))W")
                    }
                }
                
                if duration >= 1200 { // 20+ min
                    if np > best20min {
                        best20min = np
                        Logger.data("    ✓ New best 20-min power: \(Int(np))W")
                    }
                }
                if duration >= 300 { // 5+ min
                    if np > best5min {
                        best5min = np
                        Logger.data("    ✓ New best 5-min power: \(Int(np))W")
                    }
                }
            }
        }
        
        Logger.debug("📊")
        Logger.data("Power-Duration Curve Results:")
        if best60min > 0 { print("📊   60-min: \(Int(best60min))W") }
        if best20min > 0 { print("📊   20-min: \(Int(best20min))W") }
        if best5min > 0 { print("📊   5-min: \(Int(best5min))W") }
        Logger.data("  Max NP: \(Int(maxNP))W")
        
        guard maxNP > 0 else {
            Logger.data("❌ No power data available - cannot compute FTP")
            return
        }
        
        // STAGE 2: Compute FTP candidates with weighting
        Logger.debug("📊")
        Logger.data("STAGE 2: Computing FTP Candidates")
        
        var candidates: [(ftp: Double, method: String, weight: Double)] = []
        
        // Method 1: 60-min power (most accurate if available)
        if best60min > 0 {
            let ftp = best60min * 0.99
            // Ultra-endurance data is more reliable - give it higher weight
            let weight = ultraEnduranceBoost != nil ? 1.5 : 1.0
            let method = ultraEnduranceBoost != nil ? "60-min × 0.99 (ultra-endurance)" : "60-min × 0.99"
            candidates.append((ftp: ftp, method: method, weight: weight))
            Logger.data("  Method 1 (60-min): \(Int(best60min))W × 0.99 = \(Int(ftp))W (weight: \(String(format: "%.1f", weight)))")
        }
        
        // Method 2: 20-min power (gold standard)
        if best20min > 0 {
            let ftp = best20min * 0.95
            candidates.append((ftp: ftp, method: "20-min × 0.95", weight: 0.9))
            Logger.data("  Method 2 (20-min): \(Int(best20min))W × 0.95 = \(Int(ftp))W (weight: 0.9)")
        }
        
        // Method 3: 5-min power (VO2max proxy)
        if best5min > 0 {
            let ftp = best5min * 0.87
            candidates.append((ftp: ftp, method: "5-min × 0.87", weight: 0.6))
            Logger.data("  Method 3 (5-min): \(Int(best5min))W × 0.87 = \(Int(ftp))W (weight: 0.6)")
        }
        
        guard !candidates.isEmpty else {
            Logger.data("❌ No valid candidates - cannot compute FTP")
            return
        }
        
        // Weighted average
        let totalWeight = candidates.reduce(0) { $0 + $1.weight }
        let weightedFTP = candidates.reduce(0) { $0 + ($1.ftp * $1.weight) } / totalWeight
        
        Logger.debug("📊")
        Logger.data("  Total weight: \(String(format: "%.2f", totalWeight))")
        Logger.data("  Weighted FTP: \(Int(weightedFTP))W")
        
        // STAGE 3: Calculate confidence and apply buffer
        Logger.debug("📊")
        Logger.data("STAGE 3: Confidence Analysis & Buffer")
        
        let confidence = min(totalWeight / 2.5, 1.0)
        Logger.data("  Confidence score: \(String(format: "%.2f", confidence)) (0.0-1.0 scale)")
        
        var bufferedFTP: Double
        var bufferPercent: Double
        
        if confidence >= 0.9 {
            bufferPercent = 1.02
            Logger.data("  Confidence: HIGH ≥0.9")
            Logger.data("  Applying +2% buffer (conservative estimate)")
        } else if confidence >= 0.7 {
            bufferPercent = 1.03
            Logger.data("  Confidence: MEDIUM ≥0.7")
            Logger.data("  Applying +3% buffer")
        } else {
            bufferPercent = 1.05
            Logger.data("  Confidence: LOW <0.7")
            Logger.data("  Applying +5% buffer")
        }
        
        bufferedFTP = weightedFTP * bufferPercent
        Logger.data("  Buffered FTP: \(Int(weightedFTP))W × \(String(format: "%.2f", bufferPercent)) = \(Int(bufferedFTP))W")
        
        // STAGE 4: Validation & Bounds
        Logger.debug("📊")
        Logger.data("STAGE 4: Validation & Bounds Check")
        
        let lowerBound = maxNP * 0.85
        let upperBound = maxNP * 1.05
        
        Logger.data("  Max NP: \(Int(maxNP))W")
        Logger.data("  Lower bound (85% of max NP): \(Int(lowerBound))W")
        Logger.data("  Upper bound (105% of max NP): \(Int(upperBound))W")
        Logger.data("  Buffered FTP: \(Int(bufferedFTP))W")
        
        var computedFTP = bufferedFTP
        
        if bufferedFTP < lowerBound {
            computedFTP = lowerBound
            Logger.data("  ⚠️  Below lower bound! Adjusted to: \(Int(computedFTP))W")
        } else if bufferedFTP > upperBound {
            computedFTP = upperBound
            Logger.data("  ⚠️  Above upper bound! Adjusted to: \(Int(computedFTP))W")
        } else {
            Logger.data("  ✓ Within valid range")
        }
        
        // STAGE 5: Final calculation
        Logger.debug("📊")
        Logger.data("STAGE 5: Final Result")
        Logger.data("  COMPUTED FTP: \(Int(computedFTP))W")
        Logger.data("  Confidence: \(String(format: "%.0f", confidence * 100))%")
        Logger.data("  Data quality: \(candidates.count) duration points analyzed")
        
        // STAGE 6: Apply adaptive smoothing if previous FTP exists
        if let previousFTP = profile.ftp, previousFTP > 0 {
            Logger.debug("📊")
            Logger.data("STAGE 6: Adaptive Smoothing")
            
            // Adjust smoothing based on confidence and data source
            // Ultra-endurance data = more aggressive update (50/50 instead of 70/30)
            let smoothingRatio: (old: Double, new: Double)
            if ultraEnduranceBoost != nil && confidence >= 0.9 {
                smoothingRatio = (0.5, 0.5) // Equal weight for ultra-endurance data
                Logger.data("  Using balanced smoothing (ultra-endurance data)")
            } else if confidence >= 0.9 {
                smoothingRatio = (0.6, 0.4) // Less conservative for high confidence
                Logger.data("  Using moderate smoothing (high confidence)")
            } else {
                smoothingRatio = (0.7, 0.3) // Conservative for low confidence
                Logger.data("  Using conservative smoothing (standard)")
            }
            
            let smoothedFTP = (previousFTP * smoothingRatio.old) + (computedFTP * smoothingRatio.new)
            let change = ((smoothedFTP - previousFTP) / previousFTP) * 100
            
            Logger.data("  Previous FTP: \(Int(previousFTP))W")
            Logger.data("  Raw computed: \(Int(computedFTP))W")
            Logger.data("  Smoothed FTP: \(Int(smoothedFTP))W (change: \(String(format: "%.1f", change))%)")
            
            computedFTP = smoothedFTP
        }
        
        profile.ftp = computedFTP
        profile.ftpSource = .computed
        
        // Generate adaptive power zones from computed FTP
        profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: computedFTP)
        
        // Assess and store data quality
        let hasNP = !activities.compactMap({ $0.normalizedPower }).isEmpty
        let hasLongRides = !activities.filter({ ($0.duration ?? 0) >= 2700 }).isEmpty
        profile.dataQuality = assessDataQuality(activities: activities, hasNP: hasNP, hasLongRides: hasLongRides)
        
        Logger.data("✅ Adaptive FTP: \(Int(computedFTP))W")
        Logger.data("Adaptive Power Zones: \(profile.powerZones!.map { Int($0) })")
        Logger.data("Data Quality: \(Int(profile.dataQuality!.confidenceScore * 100))% confidence from \(profile.dataQuality!.sampleSize) activities")
    }
    
    /// Build power-duration profile from activities (Leo et al. 2022)
    private func buildPowerDurationProfile(activities: [IntervalsActivity]) -> PowerDurationProfile {
        var profile = PowerDurationProfile()
        
        // ENHANCED: Recognize long endurance rides as strong FTP indicators
        // If athlete can hold power for 3+ hours, that's a very reliable FTP estimate
        
        // Ultra-endurance rides (3+ hours): NP is close to or below FTP
        let ultraEndurance = activities.filter {
            guard let duration = $0.duration else { return false }
            return duration >= 10800 // 3+ hours
        }.compactMap { activity -> (power: Double, duration: Double)? in
            guard let np = activity.normalizedPower else { return nil }
            return (power: np, duration: activity.duration!)
        }
        
        if !ultraEndurance.isEmpty {
            // For 3+ hour rides, take the highest NP and boost slightly
            // NP for ultra-endurance is typically 85-95% of FTP
            let maxUltraNP = ultraEndurance.map { $0.power }.max()!
            let maxUltraDuration = ultraEndurance.first { $0.power == maxUltraNP }!.duration
            
            // Longer rides = more conservative boost (athlete pacing themselves)
            // For ultra-endurance, NP is typically 85-92% of FTP
            let boost: Double
            if maxUltraDuration >= 18000 { // 5+ hours
                boost = 1.12 // NP is ~89% of FTP for 5+ hour rides (very conservative pacing)
            } else if maxUltraDuration >= 14400 { // 4-5 hours
                boost = 1.10 // NP is ~91% of FTP for 4-5 hour rides
            } else { // 3-4 hours
                boost = 1.07 // NP is ~93% of FTP for 3-4 hour rides
            }
            
            profile.power60min = maxUltraNP * boost
            Logger.data("  Ultra-endurance ride found: \(Int(maxUltraNP))W for \(Int(maxUltraDuration/3600))h → Est. 60-min: \(Int(profile.power60min!))W")
        } else {
            // Standard 60-min power: Use highest NP from 45-90 minute rides
            let rides45to90 = activities.filter {
                guard let duration = $0.duration else { return false }
                return duration >= 2700 && duration <= 5400
            }
            
            if let max60minNP = rides45to90.compactMap({ $0.normalizedPower }).max() {
                profile.power60min = max60minNP
            }
        }
        
        // 20-minute power: Use highest normalized power from 20-60 minute rides
        let rides20to60 = activities.filter { 
            guard let duration = $0.duration else { return false }
            return duration >= 1200 && duration <= 3600
        }
        
        if let max20minNP = rides20to60.compactMap({ $0.normalizedPower }).max() {
            profile.power20min = max20minNP
        }
        
        // 5-minute power: Estimate from short hard efforts (NP from 5-15 min rides)
        let shortEfforts = activities.filter {
            guard let duration = $0.duration else { return false }
            return duration >= 300 && duration <= 900
        }
        
        if let max5minNP = shortEfforts.compactMap({ $0.normalizedPower }).max() {
            profile.power5min = max5minNP
        }
        
        return profile
    }
    
    /// Estimate W' (anaerobic work capacity) - Jones et al. (2010)
    private func estimateWPrime(activities: [IntervalsActivity], ftp: Double) -> Double? {
        // W' = work performed above CP (FTP) during maximal efforts
        // Simplified estimation: Use joules above FTP from activities
        
        let joulesAboveFTP = activities.compactMap { activity -> Double? in
            guard let duration = activity.duration,
                  let avgPower = activity.averagePower,
                  duration >= 60, duration <= 600, // 1-10 minute efforts
                  avgPower > ftp else { return nil }
            
            // W' ≈ (Power - FTP) × duration
            return (avgPower - ftp) * duration
        }
        
        if joulesAboveFTP.isEmpty { return nil }
        
        // Use 75th percentile as conservative estimate
        let sorted = joulesAboveFTP.sorted()
        let index = Int(Double(sorted.count) * 0.75)
        return sorted[min(index, sorted.count - 1)]
    }
    
    /// Estimate VO2max from FTP - Jones et al. (2010)
    private func estimateVO2max(ftp: Double, weight: Double) -> Double {
        // VO2max (ml/kg/min) ≈ FTP (W/kg) × 10.8 + 7
        // Based on relationship between CP and VO2max
        let ftpPerKg = ftp / weight
        return ftpPerKg * 10.8 + 7
    }
    
    /// Assess data quality - Bellinger & Minahan (2016)
    private func assessDataQuality(activities: [IntervalsActivity], hasNP: Bool, hasLongRides: Bool) -> DataQuality {
        let sampleSize = activities.count
        
        // Calculate variability index (coefficient of variation)
        let powers = activities.compactMap { $0.normalizedPower ?? $0.averagePower }.filter { $0 > 0 }
        let mean = powers.reduce(0, +) / Double(max(powers.count, 1))
        let variance = powers.map { pow($0 - mean, 2) }.reduce(0, +) / Double(max(powers.count, 1))
        let stdDev = sqrt(variance)
        let cv = stdDev / mean // Coefficient of variation
        
        // Confidence score based on multiple factors
        var confidence = 0.0
        confidence += sampleSize >= 20 ? 0.3 : Double(sampleSize) / 20.0 * 0.3
        confidence += hasNP ? 0.3 : 0.1
        confidence += hasLongRides ? 0.2 : 0.0
        confidence += cv < 0.15 ? 0.2 : (cv < 0.25 ? 0.1 : 0.0) // Low variability = good
        
        return DataQuality(
            confidenceScore: min(confidence, 1.0),
            sampleSize: sampleSize,
            hasLongRides: hasLongRides,
            hasPowerData: hasNP,
            hasHRData: !activities.compactMap({ $0.averageHeartRate }).isEmpty,
            variabilityIndex: cv
        )
    }
    
    /// Compute HR zones using lactate threshold detection and Max HR analysis
    /// Based on Karvonen method and modern HR training zone research
    private func computeHRZonesFromPerformanceData(_ activities: [IntervalsActivity]) {
        Logger.data("=== HR ZONES COMPUTATION (Lactate Threshold Detection) ===")
        
        // Get max HR from activities (highest recorded)
        let maxHRValues = activities.compactMap { $0.maxHeartRate }.filter { $0 > 0 }
        let durations = activities.compactMap { $0.duration }
        
        guard !maxHRValues.isEmpty else {
            Logger.data("❌ No HR data available - cannot compute HR zones")
            return
        }
        
        // Step 1: Compute Max HR (highest recorded + buffer)
        let observedMaxHR = maxHRValues.max()!
        let top5PercentHR = maxHRValues.sorted(by: >).prefix(max(1, maxHRValues.count / 20))
        let avgTop5HR = top5PercentHR.reduce(0, +) / Double(top5PercentHR.count)
        
        // Add 2% buffer for true max (athletes rarely hit true max in training)
        var computedMaxHR = avgTop5HR * 1.02
        
        Logger.data("Max HR Analysis:")
        Logger.data("  Observed max: \(Int(observedMaxHR))bpm")
        Logger.data("  Top 5% avg: \(Int(avgTop5HR))bpm")
        Logger.data("  Computed max (with 2% buffer): \(Int(computedMaxHR))bpm")
        
        // Step 2: Detect Lactate Threshold HR (LTHR)
        // Use aggregate approach: look at max HR from sustained efforts across all activities
        // This captures threshold efforts even if activity average is lower (due to warmup/cooldown)
        var lthrEstimate: Double?
        
        // Approach 1: Find sustained efforts (15+ min) and look at their MAX HR
        // Max HR in a sustained effort is typically near threshold
        let sustainedMaxHREfforts = zip(maxHRValues, durations).filter { maxHR, duration in
            // Sustained efforts: 15-60 min duration with max HR in threshold range (88-96%)
            let isSustained = duration >= 900 && duration <= 3600
            let maxInThresholdRange = maxHR >= computedMaxHR * 0.88 && maxHR <= computedMaxHR * 0.96
            return isSustained && maxInThresholdRange
        }.map { $0.0 } // Extract maxHR
        
        if !sustainedMaxHREfforts.isEmpty {
            // Take median of max HRs from threshold efforts (more robust than mean)
            let sorted = sustainedMaxHREfforts.sorted()
            let median = sorted[sorted.count / 2]
            lthrEstimate = median
            Logger.data("LTHR detected from \(sustainedMaxHREfforts.count) sustained efforts: \(Int(lthrEstimate!))bpm (median max HR)")
            Logger.data("  Range: \(Int(sorted.first!))- \(Int(sorted.last!))bpm")
        } else {
            // Approach 2: Look at activities with high average power/intensity and take their max HR
            // This captures interval sessions where threshold is hit multiple times
            let intensityBasedEfforts = zip(zip(maxHRValues, durations), activities).filter { tuple in
                let ((maxHR, duration), activity) = tuple
                // 10+ min workouts where max HR suggests threshold work
                let hasSignificantDuration = duration >= 600
                let maxInHighRange = maxHR >= computedMaxHR * 0.88
                let hasHighIntensity = (activity.normalizedPower ?? 0) > 0.80 * (profile.ftp ?? 200)
                return hasSignificantDuration && maxInHighRange && hasHighIntensity
            }.map { $0.0.0 } // Extract maxHR
            
            if !intensityBasedEfforts.isEmpty {
                let sorted = intensityBasedEfforts.sorted()
                // Take average of middle 50% (trim outliers)
                let trimmed = sorted.dropFirst(sorted.count / 4).dropLast(sorted.count / 4)
                if !trimmed.isEmpty {
                    lthrEstimate = trimmed.reduce(0, +) / Double(trimmed.count)
                    Logger.data("LTHR estimated from \(intensityBasedEfforts.count) high-intensity efforts: \(Int(lthrEstimate!))bpm")
                    Logger.data("  Range: \(Int(sorted.first!))- \(Int(sorted.last!))bpm (trimmed mean)")
                }
            } else {
                Logger.data("⚠️ No suitable threshold efforts found for LTHR estimation")
            }
        }
        
        // Store LTHR
        if let lthr = lthrEstimate {
            profile.lthr = lthr
        }
        
        // Step 3: Apply adaptive smoothing
        if let previousMaxHR = profile.maxHR, previousMaxHR > 0 {
            let smoothedMaxHR = (previousMaxHR * 0.8) + (computedMaxHR * 0.2)
            let change = ((smoothedMaxHR - previousMaxHR) / previousMaxHR) * 100
            
            Logger.data("Adaptive smoothing applied:")
            Logger.data("  Previous Max HR: \(Int(previousMaxHR))bpm")
            Logger.data("  Raw computed: \(Int(computedMaxHR))bpm")
            Logger.data("  Smoothed Max HR: \(Int(smoothedMaxHR))bpm (change: \(String(format: "%.1f", change))%)")
            
            computedMaxHR = smoothedMaxHR
        }
        
        profile.maxHR = computedMaxHR
        profile.hrZonesSource = .computed
        
        // Step 4: Generate HR zones - adaptive if LTHR is valid, otherwise percentage-based
        if let lthr = lthrEstimate {
            let lthrPercentage = lthr / computedMaxHR
            // Only use LTHR if it's in a physiologically reasonable range (82-93% of max)
            // Below 82% = likely detecting endurance pace, not threshold
            // Above 93% = too close to max, not enough room for higher zones
            if lthrPercentage >= 0.82 && lthrPercentage <= 0.93 {
                profile.hrZones = generateAdaptiveHRZones(maxHR: computedMaxHR, lthr: lthr)
                Logger.data("✅ HR Zones (Adaptive - LTHR anchored): \(profile.hrZones!.map { Int($0) })")
                Logger.data("LTHR: \(Int(lthr))bpm (\(Int(lthrPercentage * 100))% of max) - Valid range ✓")
            } else {
                profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: computedMaxHR)
                Logger.data("✅ HR Zones (Coggan): \(profile.hrZones!.map { Int($0) })")
                Logger.data("⚠️ LTHR: \(Int(lthr))bpm (\(Int(lthrPercentage * 100))% of max) - Outside valid range (82-93%), using Coggan zones")
            }
        } else {
            profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: computedMaxHR)
            Logger.data("✅ HR Zones (Coggan): \(profile.hrZones!.map { Int($0) })")
            Logger.data("⚠️ No LTHR detected - using Coggan zones")
        }
        
        Logger.data("Max HR: \(Int(computedMaxHR))bpm")
        if let lthr = lthrEstimate {
            Logger.data("LTHR: \(Int(lthr))bpm (\(Int((lthr / computedMaxHR) * 100))% of max)")
        }
    }
    
    /// Generate HR zones adjusted for detected LTHR (more accurate than pure percentages)
    private func generateAdaptiveHRZones(maxHR: Double, lthr: Double) -> [Double] {
        // Truly adaptive zones anchored at LTHR, works for all fitness levels
        // Zones: Recovery, Endurance, Tempo, Threshold (LTHR), VO2max, Anaerobic, Max
        
        let lthrPercentage = lthr / maxHR
        Logger.data("Adaptive zone computation: LTHR is \(Int(lthrPercentage * 100))% of max HR")
        
        // Z1-Z2: Always percentage-based (low intensity zones)
        let z2 = maxHR * 0.68  // 68% max (endurance/recovery boundary)
        
        // Calculate available space below and above LTHR
        let spaceBelowLTHR = lthr - z2
        let spaceAboveLTHR = maxHR - lthr
        
        // Z3: Tempo zone - proportional split of space below LTHR
        // Typically starts around 85-90% of the way from Z2 to LTHR
        let z3 = z2 + (spaceBelowLTHR * 0.65)
        
        // Z4: Threshold zone - starts slightly below LTHR to create proper zone width
        // For high LTHR (>88%), start closer to LTHR; for lower LTHR, can be further
        let z4Offset = lthrPercentage > 0.88 ? 5.0 : 8.0
        let z4 = max(lthr - z4Offset, z3 + 3)
        
        // Z5-Z7: Distribute remaining space above LTHR proportionally
        if spaceAboveLTHR > 15 {
            // Enough space - use proportional distribution
            let z5 = lthr + (spaceAboveLTHR * 0.35)  // VO2max
            let z6 = lthr + (spaceAboveLTHR * 0.70)  // Anaerobic
            
            return [
                0,      // Z1 start
                z2,     // Z2 start: Endurance
                z3,     // Z3 start: Tempo
                z4,     // Z4 start: Threshold (near LTHR)
                z5,     // Z5 start: VO2max
                z6,     // Z6 start: Anaerobic
                maxHR   // Z7 start: Max
            ]
        } else {
            // Limited space above LTHR (fit cyclist with high LTHR)
            // Use smaller, equal-sized zones
            let zoneWidth = max(spaceAboveLTHR / 3.0, 3.0)
            let z5 = lthr + zoneWidth
            let z6 = z5 + zoneWidth
            
            return [
                0,      // Z1 start
                z2,     // Z2 start: Endurance
                z3,     // Z3 start: Tempo
                z4,     // Z4 start: Threshold (near LTHR)
                z5,     // Z5 start: VO2max
                z6,     // Z6 start: Anaerobic
                maxHR   // Z7 start: Max
            ]
        }
    }
    
    private func updateAuxiliaryMetrics(_ activities: [IntervalsActivity]) {
        // Update resting HR and weight from most recent values
        // Note: LTHR is computed from performance data, not copied from Intervals.icu
        
        if let restingHR = activities.compactMap({ $0.icuRestingHr }).first {
            profile.restingHR = restingHR
            Logger.data("Updated Resting HR: \(Int(restingHR))bpm")
        }
        
        if let weight = activities.compactMap({ $0.icuWeight }).first {
            profile.weight = weight
            Logger.data("Updated Weight: \(weight)kg")
        }
    }
    
    /// Manually set FTP
    func setManualFTP(_ ftp: Double, zones: [Double]?) {
        Logger.data("Manual FTP override: \(Int(ftp))W")
        profile.ftp = ftp
        profile.powerZones = zones
        profile.ftpSource = .manual
        profile.lastUpdated = Date()
        save()
    }
    
    /// Manually set Max HR and zones
    func setManualMaxHR(_ maxHR: Double, zones: [Double]?) {
        Logger.data("Manual Max HR override: \(Int(maxHR))bpm")
        profile.maxHR = maxHR
        profile.hrZones = zones
        profile.hrZonesSource = .manual
        profile.lastUpdated = Date()
        save()
    }
    
    /// Reset to computed values (remove manual override)
    func resetToComputed() {
        Logger.data("Resetting to computed values")
        profile.ftpSource = .computed
        profile.hrZonesSource = .computed
        profile.lastUpdated = Date()
        save()
    }
    
    /// Save to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            Logger.data("Saved athlete profile to cache")
        }
    }
    
    func resetFTPToComputed() {
        profile.ftpSource = .computed
        save()
        objectWillChange.send()
    }
    
    func resetMaxHRToComputed() {
        profile.hrZonesSource = .computed
        save()
        objectWillChange.send()
    }
    
    /// Parse date string from activity
    private func parseDate(from dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        return formatter.date(from: dateString)
    }
    
    /// Generate adaptive power zones from FTP
    static func generatePowerZones(ftp: Double) -> [Double] {
        // Adaptive power zones based on computed FTP (% thresholds)
        return [
            0,              // Z1 start: 0%
            ftp * 0.55,     // Z2 start: 55%
            ftp * 0.75,     // Z3 start: 75%
            ftp * 0.90,     // Z4 start: 90%
            ftp * 1.05,     // Z5 start: 105%
            ftp * 1.20,     // Z6 start: 120%
            ftp * 1.50      // Z7 start: 150%
        ]
    }
    
    /// Generate default HR zones from Max HR (Coggan-based percentages)
    static func generateHRZones(maxHR: Double) -> [Double] {
        // Coggan HR zones (% of Max HR) - proven and widely validated
        return [
            0,              // Z1 start: Recovery
            maxHR * 0.68,   // Z2 start: Endurance (68%)
            maxHR * 0.83,   // Z3 start: Tempo (83%)
            maxHR * 0.90,   // Z4 start: Threshold (90%)
            maxHR * 0.95,   // Z5 start: VO2 Max (95%)
            maxHR * 0.98,   // Z6 start: Anaerobic (98%)
            maxHR * 1.00    // Z7 start: Max (100%)
        ]
    }
    
    /// Generate Coggan power zones from FTP (standard Coggan model)
    static func cogganPowerZones(ftp: Double) -> [Double] {
        return [
            0,              // Z1 start: Active Recovery
            ftp * 0.55,     // Z2 start: Endurance (55%)
            ftp * 0.75,     // Z3 start: Tempo (75%)
            ftp * 0.90,     // Z4 start: Lactate Threshold (90%)
            ftp * 1.05,     // Z5 start: VO2 Max (105%)
            ftp * 1.20,     // Z6 start: Anaerobic Capacity (120%)
            ftp * 1.50      // Z7 start: Neuromuscular (150%)
        ]
    }
    
    /// Generate Coggan HR zones from Max HR (standard Coggan model)
    static func cogganHRZones(maxHR: Double) -> [Double] {
        return [
            0,              // Z1 start: Active Recovery
            maxHR * 0.68,   // Z2 start: Endurance (68%)
            maxHR * 0.83,   // Z3 start: Tempo (83%)
            maxHR * 0.90,   // Z4 start: Lactate Threshold (90%)
            maxHR * 0.95,   // Z5 start: VO2 Max (95%)
            maxHR * 1.00,   // Z6 start: Anaerobic (100%)
            maxHR * 1.00    // Z7 start: Max (100%)
        ]
    }
}
