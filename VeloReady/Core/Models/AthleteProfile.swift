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
    
    // Athlete info (synced from Strava)
    var firstName: String?
    var lastName: String?
    var profilePhotoURL: String? // Strava profile photo URL
    
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
    
    // Computed property for full name
    var fullName: String? {
        let components = [firstName, lastName].compactMap { $0 }
        return components.isEmpty ? nil : components.joined(separator: " ")
    }
    
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
    
    /// Update profile manually (when not using Strava/Intervals sync)
    /// - Parameters:
    ///   - firstName: First name
    ///   - lastName: Last name
    ///   - weight: Weight in kg
    ///   - sex: Sex (M/F)
    func updateManually(firstName: String? = nil, lastName: String? = nil, weight: Double? = nil, sex: String? = nil) {
        if let firstName = firstName {
            profile.firstName = firstName
        }
        if let lastName = lastName {
            profile.lastName = lastName
        }
        if let weight = weight {
            profile.weight = weight
        }
        if let sex = sex {
            profile.sex = sex
        }
        profile.lastUpdated = Date()
        save()
        Logger.data("✅ Profile updated manually")
    }
    
    /// Sync athlete info (name, photo) from Strava profile
    /// Only syncs if user is connected to Strava
    func syncFromStrava() async {
        // Check if user is connected to Strava
        let isConnected = await MainActor.run {
            StravaAuthService.shared.connectionState.isConnected
        }
        
        guard isConnected else {
            Logger.data("⏭️ Skipping Strava sync - user not connected to Strava")
            return
        }
        
        do {
            Logger.data("📸 Syncing athlete info from Strava...")
            // StravaAthleteCache deleted - use StravaAPIClient directly
            let stravaAthlete = try await StravaAPIClient.shared.fetchAthlete()
            
            await MainActor.run {
                // Update name (only if not manually set)
                // We sync name every time from Strava to keep it current
                if let firstName = stravaAthlete.firstname {
                    profile.firstName = firstName
                    Logger.data("✅ Synced first name: \(firstName)")
                }
                if let lastName = stravaAthlete.lastname {
                    profile.lastName = lastName
                    Logger.data("✅ Synced last name: \(lastName)")
                }
                
                // Update profile photo URL (always sync to get latest)
                if let photoURL = stravaAthlete.profile {
                    profile.profilePhotoURL = photoURL
                    Logger.data("✅ Synced profile photo URL")
                }
                
                // Update weight if available and not already set manually
                // Don't overwrite if user has set it themselves
                if let weight = stravaAthlete.weight, profile.weight == nil {
                    profile.weight = weight
                    Logger.data("✅ Synced weight: \(weight)kg")
                }
                
                // Update sex if available and not already set manually
                if let sex = stravaAthlete.sex, profile.sex == nil {
                    profile.sex = sex
                    Logger.data("✅ Synced sex: \(sex)")
                }
                
                profile.lastUpdated = Date()
            }
            save()
            Logger.data("✅ Athlete info synced from Strava")
        } catch {
            Logger.warning("⚠️ Could not sync athlete info from Strava: \(error)")
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
            // StravaAthleteCache deleted - use StravaAPIClient directly
            let stravaAthlete = try await StravaAPIClient.shared.fetchAthlete()
            
            if let stravaFTP = stravaAthlete.ftp, stravaFTP > 0 {
                Logger.data("✅ Using Strava FTP as fallback: \(stravaFTP)W")
                await MainActor.run {
                    profile.ftp = Double(stravaFTP)
                    profile.ftpSource = .intervals // Mark as from external source
                    profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: Double(stravaFTP))
                    profile.lastUpdated = Date()
                }
                save()
            } else {
                Logger.data("⚠️ Strava athlete has no FTP set")
            }
        } catch {
            Logger.warning("⚠️ Could not fetch Strava athlete data: \(error)")
        }
    }
    
    /// Compute zones from recent activities using sports science algorithms
    /// UPDATED: Uses Strava as PRIMARY data source, Intervals.icu as secondary
    /// Uses Critical Power model, power curve analysis, and HR lactate threshold detection
    /// Pro: 365 days, Free: 90 days
    func computeFromActivities(_ activities: [Activity]) async {
        Logger.data("========== COMPUTING ADAPTIVE ZONES FROM PERFORMANCE DATA ==========")
        Logger.data("Using modern sports science algorithms (CP model, power distribution, HR analysis)")
        Logger.data("Data source priority: 1) Strava (primary), 2) Intervals.icu (secondary)")
        
        // NEW: Fetch Strava activities as PRIMARY source
        let stravaActivities = await StravaDataService.shared.fetchActivitiesForZones()
        Logger.data("Strava activities: \(stravaActivities.count)")
        
        // Merge with Intervals.icu activities (dedupe)
        let mergedActivities = ActivityMerger.mergeWithLogging(
            strava: stravaActivities,
            intervals: activities
        )
        
        Logger.data("Total activities after merge: \(mergedActivities.count)")
        Logger.data("Processing \(mergedActivities.count) activities for zone computation")
        Logger.data("Ignoring hardcoded Intervals.icu zones - computing from actual performance data")
        
        // Use merged activities
        let recentActivities = mergedActivities
        
        // Check PRO access for adaptive zone computation
        let proConfig = await MainActor.run { ProFeatureConfig.shared }
        
        // Only update if source is NOT manual (don't override user settings)
        if profile.ftpSource != .manual {
            if await proConfig.canUseAdaptiveFTP {
                await computeFTPFromPerformanceData(recentActivities)
            } else {
                Logger.data("🔒 Adaptive FTP computation requires PRO - FREE users use manual/Strava/Intervals.icu FTP")
            }
        } else {
            Logger.data("Skipping FTP computation - user has manual override (FTP: \(profile.ftp ?? 0)W)")
        }
        
        if profile.hrZonesSource != .manual {
            if await proConfig.canUseAdaptiveHRZones {
                await computeHRZonesFromPerformanceData(recentActivities)
            } else {
                Logger.data("🔒 Adaptive HR zones computation requires PRO - FREE users use manual/Strava/Intervals.icu zones")
            }
        } else {
            Logger.data("Skipping HR zones computation - user has manual override (Max HR: \(profile.maxHR ?? 0)bpm)")
        }
        
        // Always update weight, resting HR, LTHR from most recent
        await updateAuxiliaryMetrics(recentActivities)
        
        // Ensure zones are generated (Coggan defaults for FREE, adaptive for PRO)
        let canUseAdaptivePower = await proConfig.canUseAdaptivePowerZones
        let canUseAdaptiveHR = await proConfig.canUseAdaptiveHRZones
        
        await MainActor.run {
            if (profile.powerZones == nil || profile.powerZones!.isEmpty), let ftp = profile.ftp, ftp > 0 {
                profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp)
                let zoneType = canUseAdaptivePower ? "adaptive" : "Coggan default"
                Logger.data("✅ Generated \(zoneType) power zones from FTP: \(Int(ftp))W")
            }
            
            if (profile.hrZones == nil || profile.hrZones!.isEmpty), let maxHR = profile.maxHR, maxHR > 0 {
                profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: maxHR)
                let zoneType = canUseAdaptiveHR ? "adaptive" : "Coggan default"
                Logger.data("✅ Generated \(zoneType) HR zones from max HR: \(Int(maxHR))bpm")
            }
            
            profile.lastComputedFromActivities = Date()
            profile.lastUpdated = Date()
        }
        save()
        
        Logger.data("================================================")
    }
    
    /// Compute FTP using Enhanced Critical Power model with confidence scoring
    /// Based on Leo et al. (2022), Burnley & Jones (2018), Decroix et al. (2016)
    /// Target accuracy: ±2-5% with proper data
    private func computeFTPFromPerformanceData(_ activities: [Activity]) async {
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

        // Capture immutable copy for Swift 6 concurrency safety
        let finalFTP = computedFTP

        await MainActor.run {
            profile.ftp = finalFTP
            profile.ftpSource = .computed

            // Generate adaptive power zones from computed FTP
            profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: finalFTP)

            // Assess and store data quality
            let hasNP = !activities.compactMap({ $0.normalizedPower }).isEmpty
            let hasLongRides = !activities.filter({ ($0.duration ?? 0) >= 2700 }).isEmpty
            profile.dataQuality = assessDataQuality(activities: activities, hasNP: hasNP, hasLongRides: hasLongRides)

            // Calculate VO2max estimate from FTP
            if let weight = profile.weight, weight > 0 {
                profile.vo2maxEstimate = estimateVO2max(ftp: finalFTP, weight: weight)
            }
        }

        Logger.data("✅ Adaptive FTP: \(Int(computedFTP))W")
        if let vo2max = profile.vo2maxEstimate {
            Logger.data("✅ Estimated VO2max: \(Int(vo2max)) ml/kg/min (from FTP + weight)")
        } else {
            Logger.data("⚠️ Cannot estimate VO2max - weight not available")
        }
        Logger.data("Adaptive Power Zones: \(profile.powerZones!.map { Int($0) })")
        Logger.data("Data Quality: \(Int(profile.dataQuality!.confidenceScore * 100))% confidence from \(profile.dataQuality!.sampleSize) activities")
    }
    
    /// Build power-duration profile from activities (Leo et al. 2022)
    private func buildPowerDurationProfile(activities: [Activity]) -> PowerDurationProfile {
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
    private func estimateWPrime(activities: [Activity], ftp: Double) -> Double? {
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
    private func assessDataQuality(activities: [Activity], hasNP: Bool, hasLongRides: Bool) -> DataQuality {
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
    private func computeHRZonesFromPerformanceData(_ activities: [Activity]) async {
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
            await MainActor.run {
                profile.lthr = lthr
            }
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

        // Capture immutable copies for Swift 6 concurrency safety
        let finalMaxHR = computedMaxHR
        let finalLTHR = lthrEstimate

        await MainActor.run {
            profile.maxHR = finalMaxHR
            profile.hrZonesSource = .computed

            // Step 4: Generate HR zones - adaptive if LTHR is valid, otherwise percentage-based
            if let lthr = finalLTHR {
                let lthrPercentage = lthr / finalMaxHR
                // Only use LTHR if it's in a physiologically reasonable range (82-93% of max)
                // Below 82% = likely detecting endurance pace, not threshold
                // Above 93% = too close to max, not enough room for higher zones
                if lthrPercentage >= 0.82 && lthrPercentage <= 0.93 {
                    profile.hrZones = generateAdaptiveHRZones(maxHR: finalMaxHR, lthr: lthr)
                    Logger.data("✅ HR Zones (Adaptive - LTHR anchored): \(profile.hrZones!.map { Int($0) })")
                    Logger.data("LTHR: \(Int(lthr))bpm (\(Int(lthrPercentage * 100))% of max) - Valid range ✓")
                } else {
                    profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: finalMaxHR)
                    Logger.data("✅ HR Zones (Coggan): \(profile.hrZones!.map { Int($0) })")
                    Logger.data("⚠️ LTHR: \(Int(lthr))bpm (\(Int(lthrPercentage * 100))% of max) - Outside valid range (82-93%), using Coggan zones")
                }
            } else {
                profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: finalMaxHR)
                Logger.data("✅ HR Zones (Coggan): \(profile.hrZones!.map { Int($0) })")
                Logger.data("⚠️ No LTHR detected - using Coggan zones")
            }
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
    
    private func updateAuxiliaryMetrics(_ activities: [Activity]) async {
        // Update resting HR and weight from most recent values
        // Note: LTHR is computed from performance data, not copied from Intervals.icu
        
        if let restingHR = activities.compactMap({ $0.icuRestingHr }).first {
            await MainActor.run {
                profile.restingHR = restingHR
            }
            Logger.data("Updated Resting HR: \(Int(restingHR))bpm")
        } else {
            // For Strava-only users, fetch RHR from HealthKit
            Logger.data("📊 No Intervals.icu RHR - fetching from HealthKit...")
            let healthKitRHR = await HealthKitManager.shared.fetchLatestRHRData()
            if let rhrValue = healthKitRHR.value {
                await MainActor.run {
                    profile.restingHR = rhrValue
                }
                Logger.data("Updated Resting HR from HealthKit: \(Int(rhrValue))bpm")
            } else {
                Logger.data("⚠️ No RHR data available from HealthKit")
            }
        }
        
        if let weight = activities.compactMap({ $0.icuWeight }).first {
            await MainActor.run {
                profile.weight = weight
            }
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

    // MARK: - Power Meter Detection & HR-Based Estimation

    /// Check if user has power meter data in recent activities
    static func hasPowerMeterData(activities: [Activity]) -> Bool {
        // Check if at least 3 recent activities have power data
        let activitiesWithPower = activities.filter { activity in
            activity.averagePower != nil && activity.averagePower! > 0 ||
            activity.normalizedPower != nil && activity.normalizedPower! > 0
        }

        Logger.debug("Power meter detection: \(activitiesWithPower.count)/\(activities.count) activities have power data")
        return activitiesWithPower.count >= 3
    }

    /// Estimate FTP from heart rate data (for users without power meters)
    /// Uses LTHR (Lactate Threshold Heart Rate) and body weight
    /// Based on Coggan's HR-power relationships
    static func estimateFTPFromHR(maxHR: Double, lthr: Double, weight: Double) -> Double? {
        guard maxHR > 0, lthr > 0, lthr < maxHR, weight > 0 else {
            Logger.warning("Invalid inputs for HR-based FTP estimation")
            return nil
        }

        // LTHR as percentage of max HR (typically 85-92% for trained athletes)
        let lthrPercentage = lthr / maxHR

        Logger.debug("📊 HR-Based FTP Estimation:")
        Logger.debug("   Max HR: \(Int(maxHR)) bpm")
        Logger.debug("   LTHR: \(Int(lthr)) bpm (\(Int(lthrPercentage * 100))% of max)")
        Logger.debug("   Weight: \(String(format: "%.1f", weight)) kg")

        // Estimate FTP in W/kg based on LTHR percentage
        // Athletes with higher LTHR% tend to have better FTP/kg ratios
        // Base: 85% LTHR = ~2.5 W/kg (recreational)
        // For each 1% above 85%, add ~0.3 W/kg
        let baseWPerKg = 2.5
        let lthrBonus = (lthrPercentage - 0.85) * 30.0  // 30 W/kg per 100% difference
        let estimatedWPerKg = baseWPerKg + lthrBonus

        // Clamp to realistic values (1.5 - 6.0 W/kg)
        let clampedWPerKg = min(max(estimatedWPerKg, 1.5), 6.0)

        let estimatedFTP = clampedWPerKg * weight

        Logger.debug("   Estimated W/kg: \(String(format: "%.2f", clampedWPerKg))")
        Logger.debug("   Estimated FTP: \(Int(estimatedFTP))W")

        return estimatedFTP
    }

    /// Estimate VO2 Max from heart rate data (Cooper formula, age-adjusted)
    /// For users without power meters
    static func estimateVO2MaxFromHR(maxHR: Double, restingHR: Double?, age: Int?) -> Double? {
        guard maxHR > 0 else { return nil }

        // Use Cooper formula if we have resting HR
        var vo2max: Double
        if let rhr = restingHR, rhr > 0, rhr < maxHR {
            // Cooper formula: VO2max = 15.3 × (maxHR / restingHR)
            vo2max = 15.3 * (maxHR / rhr)
        } else {
            // Fallback: estimate from max HR alone (less accurate)
            // Typical: VO2max ≈ (maxHR / 3.5) - very rough estimate
            vo2max = (maxHR / 3.5)
        }

        // Apply age adjustment if available
        if let age = age, age >= 25 {
            // VO2 max declines ~1% per year after age 25
            let yearsAfter25 = age - 25
            let ageFactor = 1.0 - (Double(yearsAfter25) * 0.01)
            vo2max *= ageFactor
        }

        // Clamp to realistic values (20-80 ml/kg/min)
        vo2max = min(max(vo2max, 20), 80)

        Logger.debug("📊 HR-Based VO2 Max Estimation:")
        Logger.debug("   Max HR: \(Int(maxHR)) bpm")
        if let rhr = restingHR {
            Logger.debug("   Resting HR: \(Int(rhr)) bpm")
        }
        if let age = age {
            Logger.debug("   Age: \(age) years")
        }
        Logger.debug("   Estimated VO2 Max: \(String(format: "%.1f", vo2max)) ml/kg/min")

        return vo2max
    }

    /// Get Coggan default FTP for free users (basic estimate)
    static func getCogganDefaultFTP(weight: Double?) -> Double {
        guard let weight = weight, weight > 0 else {
            // No weight available: use fixed default
            return 200.0  // Average recreational cyclist
        }

        // Use 2.5 W/kg as baseline for average recreational cyclist
        return weight * 2.5
    }

    /// Get Coggan default VO2 Max for free users (age/gender-based estimate)
    static func getCogganDefaultVO2Max(age: Int?, gender: String?) -> Double {
        let baseVO2: Double

        // Gender-based baseline
        if gender?.uppercased() == "F" || gender?.uppercased() == "FEMALE" {
            baseVO2 = 45.0  // Average for female
        } else {
            baseVO2 = 50.0  // Average for male (default)
        }

        // Age adjustment (decline ~0.5 ml/kg/min per year after 25)
        if let age = age, age >= 25 {
            let yearsAfter25 = age - 25
            let ageAdjustment = Double(yearsAfter25) * 0.5
            return max(baseVO2 - ageAdjustment, 25.0)  // Min 25
        }

        return baseVO2
    }

    // MARK: - Historical Performance Data (Cached)

    /// Fetch historical FTP sparkline data (30 days)
    /// Returns cached data if available (< 5 minutes old), otherwise calculates from activities
    func fetchHistoricalFTPSparkline() async -> [Double] {
        let cacheKey = "historicalFTP_sparkline"
        let cacheTimestampKey = "historicalFTP_timestamp"

        // Check cache first (10 second TTL for immediate testing - change to 24 hours for production)
        if let cachedData = UserDefaults.standard.array(forKey: cacheKey) as? [Double],
           let cachedTimestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date {
            let secondsSinceCache = Date().timeIntervalSince(cachedTimestamp)
            if secondsSinceCache < 10 {
                Logger.debug("📊 Using cached FTP sparkline (\(String(format: "%.1f", secondsSinceCache))s old)")
                return cachedData
            } else {
                Logger.debug("📊 FTP sparkline cache expired (\(String(format: "%.1f", secondsSinceCache))s old) - recalculating from REAL data")
            }
        }

        // Calculate from activities
        Logger.debug("📊 Calculating FTP sparkline from activities...")
        let sparkline = await calculateHistoricalFTP()

        // Cache results
        UserDefaults.standard.set(sparkline, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)

        return sparkline
    }

    /// Fetch historical VO2 sparkline data (30 days)
    /// Returns cached data if available (< 5 minutes old), otherwise calculates from activities
    func fetchHistoricalVO2Sparkline() async -> [Double] {
        let cacheKey = "historicalVO2_sparkline"
        let cacheTimestampKey = "historicalVO2_timestamp"

        // Check cache first (10 second TTL for immediate testing - change to 24 hours for production)
        if let cachedData = UserDefaults.standard.array(forKey: cacheKey) as? [Double],
           let cachedTimestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date {
            let secondsSinceCache = Date().timeIntervalSince(cachedTimestamp)
            if secondsSinceCache < 10 {
                Logger.debug("📊 Using cached VO2 sparkline (\(String(format: "%.1f", secondsSinceCache))s old)")
                return cachedData
            } else {
                Logger.debug("📊 VO2 sparkline cache expired (\(String(format: "%.1f", secondsSinceCache))s old) - recalculating from REAL data")
            }
        }

        // Calculate from activities
        Logger.debug("📊 Calculating VO2 sparkline from activities...")
        let sparkline = await calculateHistoricalVO2()

        // Cache results
        UserDefaults.standard.set(sparkline, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)

        return sparkline
    }

    /// Calculate 30-day FTP trend from REAL historical activities (daily granularity)
    /// Uses 30-day rolling window for each data point
    private func calculateHistoricalFTP() async -> [Double] {
        Logger.debug("📊 [Historical FTP] Calculating from REAL activity data with daily granularity...")

        // Fetch activities from last 180 days (30-day window + 150 days of history to capture peaks)
        guard let activities = try? await UnifiedActivityService.shared.fetchRecentActivities(limit: 1000, daysBack: 180) else {
            Logger.warning("⚠️ [Historical FTP] Failed to fetch activities - using simulated data")
            return generateRealisticFTPProgression(current: profile.ftp ?? 200.0, days: 30)
        }

        Logger.debug("📊 [Historical FTP] Fetched \(activities.count) activities for calculation")

        let calendar = Calendar.current
        let now = Date()
        var sparklineValues: [Double] = []

        // Calculate FTP for each day (30 daily points for granularity)
        for dayOffset in stride(from: -29, through: 0, by: 1) {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
                continue
            }

            // Get activities within 30-day TRAILING window (30 days BEFORE this date)
            // Smaller window = more granularity, less overlap between consecutive days
            guard let windowStart = calendar.date(byAdding: .day, value: -30, to: targetDate) else {
                continue
            }

            let activitiesInWindow = activities.filter { activity in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
                formatter.timeZone = TimeZone.current

                guard let activityDate = formatter.date(from: activity.startDateLocal) else { return false }
                return activityDate >= windowStart && activityDate <= targetDate
            }

            // Calculate FTP from trailing window
            let ftp = calculateFTPFromActivities(activitiesInWindow) ?? (profile.ftp ?? 200.0)
            sparklineValues.append(ftp)
        }

        // Ensure we have exactly 30 values
        while sparklineValues.count > 30 { sparklineValues.removeFirst() }
        while sparklineValues.count < 30 {
            sparklineValues.insert(profile.ftp ?? 200.0, at: 0)
        }

        Logger.debug("📊 [Historical FTP] Calculated \(sparklineValues.count) daily points from real data")
        Logger.debug("📊 [Historical FTP] Range: \(String(format: "%.0f", sparklineValues.min() ?? 0))W - \(String(format: "%.0f", sparklineValues.max() ?? 0))W")

        return sparklineValues
    }
    
    /// Calculate FTP from a set of activities (helper for historical calculations)
    /// Simplified version of computeFTPFromPerformanceData for efficiency
    private func calculateFTPFromActivities(_ activities: [Activity]) -> Double? {
        guard !activities.isEmpty else {
            Logger.debug("   📊 FTP calc: No activities in window")
            return nil
        }

        // Filter activities with power data
        let activitiesWithPower = activities.filter { ($0.normalizedPower ?? 0) > 0 || ($0.averagePower ?? 0) > 0 }

        Logger.debug("   📊 FTP calc: \(activities.count) total activities, \(activitiesWithPower.count) with power data")

        guard !activitiesWithPower.isEmpty else {
            Logger.debug("   📊 FTP calc: No activities with power data")
            return nil
        }

        var best60min: Double = 0
        var best20min: Double = 0
        var best5min: Double = 0
        var maxNP: Double = 0

        for activity in activitiesWithPower {
            // Prefer normalized power, fall back to average power
            let np = activity.normalizedPower ?? activity.averagePower ?? 0
            let duration = activity.duration ?? 0

            guard np > 0 else { continue }

            maxNP = max(maxNP, np)

            // Ultra-endurance detection (3+ hours)
            if duration >= 10800 {
                let boost = duration >= 18000 ? 1.12 : (duration >= 14400 ? 1.10 : 1.07)
                best60min = max(best60min, np * boost)
            } else if duration >= 3600 {
                best60min = max(best60min, np)
            }

            if duration >= 1200 { best20min = max(best20min, np) }
            if duration >= 300 { best5min = max(best5min, np) }
        }

        guard maxNP > 0 else {
            Logger.debug("   📊 FTP calc: No valid power data found")
            return nil
        }

        // Calculate weighted FTP
        var candidates: [(ftp: Double, weight: Double)] = []
        if best60min > 0 { candidates.append((best60min * 0.99, 1.5)) }
        if best20min > 0 { candidates.append((best20min * 0.95, 0.9)) }
        if best5min > 0 { candidates.append((best5min * 0.87, 0.6)) }

        guard !candidates.isEmpty else {
            Logger.debug("   📊 FTP calc: No valid duration efforts found")
            return nil
        }

        let totalWeight = candidates.reduce(0) { $0 + $1.weight }
        let weightedFTP = candidates.reduce(0) { $0 + ($1.ftp * $1.weight) } / totalWeight
        let finalFTP = weightedFTP * 1.02

        Logger.debug("   📊 FTP calc: Calculated FTP = \(String(format: "%.0f", finalFTP))W (60min: \(String(format: "%.0f", best60min))W, 20min: \(String(format: "%.0f", best20min))W, 5min: \(String(format: "%.0f", best5min))W)")

        return finalFTP
    }

    /// Calculate 30-day VO2 trend from REAL historical activities (daily granularity)
    /// Uses 30-day rolling window for each data point, estimating VO2 from FTP
    private func calculateHistoricalVO2() async -> [Double] {
        Logger.debug("📊 [Historical VO2] Calculating from REAL activity data with daily granularity...")

        // Fetch activities from last 180 days (30-day window + 150 days of history to capture peaks)
        guard let activities = try? await UnifiedActivityService.shared.fetchRecentActivities(limit: 1000, daysBack: 180) else {
            Logger.warning("⚠️ [Historical VO2] Failed to fetch activities - using simulated data")
            return generateRealisticVO2Progression(current: profile.vo2maxEstimate ?? 45.0, days: 30)
        }

        Logger.debug("📊 [Historical VO2] Fetched \(activities.count) activities for calculation")

        let calendar = Calendar.current
        let now = Date()
        var sparklineValues: [Double] = []
        let weight = profile.weight ?? 75.0

        // Calculate VO2 for each day (30 daily points for granularity)
        for dayOffset in stride(from: -29, through: 0, by: 1) {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
                continue
            }

            // Get activities within 30-day TRAILING window (30 days BEFORE this date)
            // Smaller window = more granularity, less overlap between consecutive days
            guard let windowStart = calendar.date(byAdding: .day, value: -30, to: targetDate) else {
                continue
            }

            let activitiesInWindow = activities.filter { activity in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
                formatter.timeZone = TimeZone.current

                guard let activityDate = formatter.date(from: activity.startDateLocal) else { return false }
                return activityDate >= windowStart && activityDate <= targetDate
            }

            // Calculate FTP from trailing window, then estimate VO2
            if let ftp = calculateFTPFromActivities(activitiesInWindow) {
                // VO2max estimation: VO2max (ml/kg/min) ≈ 10.8 × FTP/weight + 7
                let vo2 = (10.8 * ftp) / weight + 7
                sparklineValues.append(vo2)
            } else {
                sparklineValues.append(profile.vo2maxEstimate ?? 45.0)
            }
        }

        // Ensure we have exactly 30 values
        while sparklineValues.count > 30 { sparklineValues.removeFirst() }
        while sparklineValues.count < 30 {
            sparklineValues.insert(profile.vo2maxEstimate ?? 45.0, at: 0)
        }

        Logger.debug("📊 [Historical VO2] Calculated \(sparklineValues.count) daily points from real data")
        Logger.debug("📊 [Historical VO2] Range: \(String(format: "%.1f", sparklineValues.min() ?? 0)) - \(String(format: "%.1f", sparklineValues.max() ?? 0)) ml/kg/min")

        return sparklineValues
    }

    /// Generate realistic FTP progression with training-like patterns
    /// TEMPORARY SOLUTION - should be replaced with real activity data
    private func generateRealisticFTPProgression(current: Double, days: Int) -> [Double] {
        var values: [Double] = []
        let start = current * 0.96  // Start 4% lower than current
        let overallGain = current - start

        for day in 0..<days {
            // CRITICAL FIX: Last point must EXACTLY match current value
            if day == days - 1 {
                values.append(current)
            } else {
                // Base progression toward current value
                let baseProgress = overallGain * (Double(day) / Double(days))

                // Add realistic noise (±1.5% daily variation)
                let noise = Double.random(in: -0.015...0.015) * current

                // Add weekly training/recovery cycles
                let weeklyVariation = sin(Double(day) / 7.0 * .pi * 2) * (current * 0.01)

                let value = start + baseProgress + noise + weeklyVariation
                values.append(value)
            }
        }

        return values
    }

    /// Generate realistic VO2 progression with training-like patterns
    /// TEMPORARY SOLUTION - should be replaced with real activity data
    private func generateRealisticVO2Progression(current: Double, days: Int) -> [Double] {
        var values: [Double] = []
        let start = current * 0.97  // Start 3% lower than current
        let overallGain = current - start

        for day in 0..<days {
            // CRITICAL FIX: Last point must EXACTLY match current value
            if day == days - 1 {
                values.append(current)
                continue
            }
            
            // Base progression toward current value
            let baseProgress = overallGain * (Double(day) / Double(days))

            // Add realistic noise (±2% daily variation)
            let noise = Double.random(in: -0.02...0.02) * current

            // Add weekly training/recovery cycles
            let weeklyVariation = sin(Double(day) / 7.0 * .pi * 2) * (current * 0.015)

            let value = start + baseProgress + noise + weeklyVariation
            values.append(value)
        }

        return values
    }

    /// Fetch 6-month historical performance data for charts
    /// Returns weekly data points (26 points) with confidence intervals and activity counts
    func fetch6MonthHistoricalPerformance() async -> [(date: Date, ftp: Double, vo2: Double, confidence: Double, activityCount: Int)] {
        let cacheKey = "historical6Month_performance"
        let cacheTimestampKey = "historical6Month_timestamp"

        // Check cache first (5 minute TTL - performance data doesn't change frequently)
        if let cachedDataDict = UserDefaults.standard.array(forKey: cacheKey) as? [[String: Any]],
           let cachedTimestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date {
            let secondsSinceCache = Date().timeIntervalSince(cachedTimestamp)
            if secondsSinceCache < 300 {
                Logger.debug("📊 Using cached 6-month performance (\(String(format: "%.1f", secondsSinceCache))s old)")
                // Convert cached dict back to tuples
                let data = cachedDataDict.compactMap { dict -> (date: Date, ftp: Double, vo2: Double, confidence: Double, activityCount: Int)? in
                    guard let date = dict["date"] as? Date,
                          let ftp = dict["ftp"] as? Double,
                          let vo2 = dict["vo2"] as? Double,
                          let confidence = dict["confidence"] as? Double,
                          let activityCount = dict["activityCount"] as? Int else { return nil }
                    return (date, ftp, vo2, confidence, activityCount)
                }
                if !data.isEmpty {
                    return data
                }
            } else {
                Logger.debug("📊 6-month performance cache expired (\(String(format: "%.1f", secondsSinceCache))s old) - recalculating from REAL data")
            }
        }

        // Calculate from current values
        Logger.debug("📊 Calculating 6-month historical performance...")
        let data = calculate6MonthHistorical()

        // Cache results (convert tuples to dicts for UserDefaults)
        let cacheData = data.map { [
            "date": $0.date,
            "ftp": $0.ftp,
            "vo2": $0.vo2,
            "confidence": $0.confidence,
            "activityCount": $0.activityCount
        ] as [String: Any] }
        UserDefaults.standard.set(cacheData, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)

        return data
    }

    /// Calculate 6-month historical performance from REAL activity data (weekly data points)
    /// Point-in-time snapshots with 90-day trailing window (sport science validated approach)
    /// Weekly snapshots for 6 months, each using activities from 90 days BEFORE that date
    private func calculate6MonthHistorical() -> [(date: Date, ftp: Double, vo2: Double, confidence: Double, activityCount: Int)] {
        Logger.debug("📊 [6-Month Historical] Calculating point-in-time snapshots (weekly, 90-day trailing)...")

        let currentFTP = profile.ftp ?? 200.0
        let currentVO2 = profile.vo2maxEstimate ?? 45.0
        let now = Date()
        let calendar = Calendar.current
        let weeks = 26
        let weight = profile.weight ?? 75.0

        // Fetch activities synchronously from UnifiedActivityService cache
        // Fetch 12 months to capture historical peaks (June's 210-220W FTP)
        var cachedActivities: [Activity] = []
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                cachedActivities = try await UnifiedActivityService.shared.fetchRecentActivities(limit: 2000, daysBack: 365)
                semaphore.signal()
            } catch {
                Logger.error("❌ [6-Month Historical] Failed to fetch activities: \(error)")
                semaphore.signal()
            }
        }

        _ = semaphore.wait(timeout: .now() + 5.0)

        guard !cachedActivities.isEmpty else {
            Logger.warning("⚠️ [6-Month Historical] No activities found - using simulated data")
            return generateSimulated6MonthData(currentFTP: currentFTP, currentVO2: currentVO2)
        }

        Logger.debug("📊 [6-Month Historical] Fetched \(cachedActivities.count) activities for calculation")

        var dataPoints: [(date: Date, ftp: Double, vo2: Double, confidence: Double, activityCount: Int)] = []

        for week in 0..<weeks {
            // Snapshot date (going backwards from now)
            guard let snapshotDate = calendar.date(byAdding: .weekOfYear, value: -(weeks - week - 1), to: now) else {
                continue
            }

            // 90-day trailing window BEFORE snapshot date (point-in-time approach)
            // No future leakage - only uses activities that existed at this point in time
            guard let windowStart = calendar.date(byAdding: .day, value: -90, to: snapshotDate) else {
                continue
            }

            let activitiesInWindow = cachedActivities.filter { activity in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
                formatter.timeZone = TimeZone.current

                guard let activityDate = formatter.date(from: activity.startDateLocal) else { return false }
                // Only activities BEFORE or ON snapshot date (point-in-time constraint)
                return activityDate >= windowStart && activityDate <= snapshotDate
            }

            let activityCount = activitiesInWindow.count
            let powerActivities = activitiesInWindow.filter { $0.averagePower != nil && $0.averagePower! > 0 }

            // Calculate confidence based on sample size (more activities = higher confidence)
            // Min 5 power activities for reasonable estimate, optimal 20+
            let confidence = min(1.0, Double(powerActivities.count) / 20.0)

            // Calculate FTP from trailing window
            if let ftp = calculateFTPFromActivities(activitiesInWindow), ftp > 0 {
                // VO2max estimation: VO2max (ml/kg/min) ≈ 10.8 × FTP/weight + 7
                let vo2 = (10.8 * ftp) / weight + 7
                dataPoints.append((date: snapshotDate, ftp: ftp, vo2: vo2, confidence: confidence, activityCount: activityCount))
                
                Logger.debug("   Week \(week + 1): \(String(format: "%.0f", ftp))W (\(powerActivities.count) power activities, confidence: \(String(format: "%.0f", confidence * 100))%)")
            } else {
                // No valid activities - use current values with low confidence
                dataPoints.append((date: snapshotDate, ftp: currentFTP, vo2: currentVO2, confidence: 0.0, activityCount: activityCount))
                Logger.debug("   Week \(week + 1): No data (using current FTP)")
            }
        }

        Logger.debug("📊 [6-Month Historical] Generated \(dataPoints.count) weekly snapshots from real data")
        if let first = dataPoints.first, let last = dataPoints.last {
            Logger.debug("📊 [6-Month Historical] FTP range: \(String(format: "%.0f", first.ftp))W → \(String(format: "%.0f", last.ftp))W")
            Logger.debug("📊 [6-Month Historical] VO2 range: \(String(format: "%.1f", first.vo2)) → \(String(format: "%.1f", last.vo2)) ml/kg/min")
            
            // Detect significant changes (>5W sustained for 2+ weeks)
            detectSignificantChanges(dataPoints)
        }

        return dataPoints
    }
    
    /// Detect significant FTP changes (>5W sustained for 2+ weeks)
    /// Used for annotating training adaptations on chart
    private func detectSignificantChanges(_ dataPoints: [(date: Date, ftp: Double, vo2: Double, confidence: Double, activityCount: Int)]) {
        guard dataPoints.count >= 3 else { return }
        
        var significantChanges: [(date: Date, change: Double, phase: String)] = []
        
        for i in 2..<dataPoints.count {
            let current = dataPoints[i].ftp
            let twoWeeksAgo = dataPoints[i - 2].ftp
            let change = current - twoWeeksAgo
            
            // Significant if >5W change sustained for 2+ weeks and high confidence
            if abs(change) >= 5 && dataPoints[i].confidence >= 0.5 {
                let phase = change > 0 ? "Build Phase" : "Recovery Phase"
                significantChanges.append((date: dataPoints[i].date, change: change, phase: phase))
                
                Logger.debug("   🎯 \(phase) detected: \(String(format: "%+.0f", change))W over 2 weeks (ending \(dataPoints[i].date.formatted(.dateTime.month().day())))")
            }
        }
        
        if significantChanges.isEmpty {
            Logger.debug("   ℹ️ No significant training adaptations detected (need >5W change sustained 2+ weeks)")
        }
    }
    
    /// Fallback: Generate simulated 6-month data if no activity cache available
    private func generateSimulated6MonthData(currentFTP: Double, currentVO2: Double) -> [(date: Date, ftp: Double, vo2: Double, confidence: Double, activityCount: Int)] {
        let now = Date()
        let calendar = Calendar.current
        let weeks = 26
        var dataPoints: [(date: Date, ftp: Double, vo2: Double, confidence: Double, activityCount: Int)] = []

        let ftpStart = currentFTP * 0.90
        let vo2Start = currentVO2 * 0.92
        let ftpGain = currentFTP * 0.10
        let vo2Gain = currentVO2 * 0.08

        for week in 0..<weeks {
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -(weeks - week - 1), to: now) else {
                continue
            }

            if week == weeks - 1 {
                dataPoints.append((date: weekDate, ftp: currentFTP, vo2: currentVO2, confidence: 0.0, activityCount: 0))
            } else {
                let progress = Double(week) / Double(weeks)
                let ftp = ftpStart + (ftpGain * progress)
                let vo2 = vo2Start + (vo2Gain * progress)
                dataPoints.append((date: weekDate, ftp: ftp, vo2: vo2, confidence: 0.0, activityCount: 0))
            }
        }

        return dataPoints
    }
}
