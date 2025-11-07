import Foundation
import SwiftUI

@MainActor
class RideDetailViewModel: ObservableObject {
    @Published private(set) var samples: [WorkoutSample] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var enrichedActivity: IntervalsActivity?
    
    func loadActivityData(activity: IntervalsActivity, apiClient: IntervalsAPIClient, profileManager: AthleteProfileManager) async {
        Logger.debug("🚴 ========== RIDE DETAIL VIEW MODEL: LOAD ACTIVITY DATA ==========")
        Logger.debug("🚴 Activity ID: \(activity.id)")
        Logger.debug("🚴 Activity Name: \(activity.name ?? "Unknown")")
        Logger.debug("🚴 Activity Type: \(activity.type ?? "Unknown")")
        Logger.debug("🚴 Start Date: \(activity.startDateLocal)")
        
        isLoading = true
        error = nil
        
        // Check cache first for all activities
        let cacheKey = CacheKey.activityStreams(activityId: activity.id, source: "any")
        if let cachedSamples: [WorkoutSample] = await CacheOrchestrator.shared.get(key: cacheKey, ttl: 604800) {
            Logger.debug("⚡ Using cached stream data (\(cachedSamples.count) samples)")
            samples = cachedSamples
            
            // Enrich with stream data
            var enriched = enrichActivityWithStreamData(activity: activity, samples: cachedSamples, profileManager: profileManager)
            
            // Calculate TSS/IF for Strava activities
            if activity.id.hasPrefix("strava_") {
                enriched = await calculateTSSAndIF(for: enriched, profileManager: profileManager)
            }
            
            enrichedActivity = enriched
            isLoading = false
            Logger.debug("🚴 ================================================================")
            return
        }
        
        Logger.debug("📡 Cache miss - fetching from API")
        
        // Check if this is a Strava activity (ID starts with "strava_")
        if activity.id.hasPrefix("strava_") {
            Logger.debug("🚴 Detected Strava activity, fetching from Strava API...")
            await loadStravaActivityData(activity: activity, profileManager: profileManager)
            return
        }
        
        do {
            Logger.debug("🚴 Attempting to fetch time-series data from Intervals.icu API...")
            // Fetch time-series data from API
            let streamData = try await apiClient.fetchActivityStreams(activityId: activity.id)
            
            Logger.debug("🚴 API Response received: \(streamData.count) samples")
            
            if streamData.isEmpty {
                Logger.warning("️ API returned empty data, falling back to generated data")
                Logger.debug("🚴 Activity metrics for fallback generation:")
                Logger.debug("🚴   - Duration: \(activity.duration ?? 0)s")
                Logger.debug("🚴   - Distance: \(activity.distance ?? 0)m")
                Logger.debug("🚴   - Avg Power: \(activity.averagePower ?? 0)W")
                Logger.debug("🚴   - Avg HR: \(activity.averageHeartRate ?? 0)bpm")
                Logger.debug("🚴   - Avg Speed: \(activity.averageSpeed ?? 0)km/h")
                
                samples = ActivityDataTransformer.generateSamples(from: activity)
                
                Logger.debug("🚴 Generated \(samples.count) fallback samples")
            } else {
                Logger.debug("✅ Successfully loaded \(streamData.count) data points from API")
                
                // Analyze the data we received
                let samplesWithPower = streamData.filter { $0.power > 0 }.count
                let samplesWithHR = streamData.filter { $0.heartRate > 0 }.count
                let samplesWithSpeed = streamData.filter { $0.speed > 0 }.count
                let samplesWithCadence = streamData.filter { $0.cadence > 0 }.count
                let samplesWithGPS = streamData.filter { $0.latitude != nil && $0.longitude != nil }.count
                
                Logger.debug("🚴 Data Quality Analysis:")
                Logger.debug("🚴   - Samples with Power: \(samplesWithPower)/\(streamData.count) (\(Int(Double(samplesWithPower)/Double(streamData.count)*100))%)")
                Logger.debug("🚴   - Samples with HR: \(samplesWithHR)/\(streamData.count) (\(Int(Double(samplesWithHR)/Double(streamData.count)*100))%)")
                Logger.debug("🚴   - Samples with Speed: \(samplesWithSpeed)/\(streamData.count) (\(Int(Double(samplesWithSpeed)/Double(streamData.count)*100))%)")
                Logger.debug("🚴   - Samples with Cadence: \(samplesWithCadence)/\(streamData.count) (\(Int(Double(samplesWithCadence)/Double(streamData.count)*100))%)")
                Logger.debug("🚴   - Samples with GPS: \(samplesWithGPS)/\(streamData.count) (\(Int(Double(samplesWithGPS)/Double(streamData.count)*100))%)")
                
                // Calculate averages from actual data
                if samplesWithPower > 0 {
                    let avgPower = streamData.filter { $0.power > 0 }.map { $0.power }.reduce(0, +) / Double(samplesWithPower)
                    Logger.debug("🚴   - Calculated Avg Power: \(Int(avgPower))W (Activity says: \(activity.averagePower ?? 0)W)")
                }
                if samplesWithHR > 0 {
                    let avgHR = streamData.filter { $0.heartRate > 0 }.map { $0.heartRate }.reduce(0, +) / Double(samplesWithHR)
                    Logger.debug("🚴   - Calculated Avg HR: \(Int(avgHR))bpm (Activity says: \(activity.averageHeartRate ?? 0)bpm)")
                }
                if samplesWithSpeed > 0 {
                    let avgSpeed = streamData.filter { $0.speed > 0 }.map { $0.speed }.reduce(0, +) / Double(samplesWithSpeed)
                    Logger.debug("🚴   - Calculated Avg Speed: \(String(format: "%.1f", avgSpeed))km/h (Activity says: \(activity.averageSpeed ?? 0)km/h)")
                }
                
                samples = streamData
                
                // Cache for future use
                let cacheKey = CacheKey.activityStreams(activityId: activity.id, source: "intervals")
                await CacheOrchestrator.shared.set(key: cacheKey, value: streamData, cachedAt: Date())
                
                // Enrich activity with calculated data if summary is missing values
                enrichedActivity = enrichActivityWithStreamData(activity: activity, samples: streamData, profileManager: profileManager)
            }
            
        } catch {
            Logger.error("Failed to load activity data: \(error)")
            Logger.error("Error type: \(type(of: error))")
            Logger.error("Error description: \(error.localizedDescription)")
            self.error = error.localizedDescription
            
            // Fall back to generated data
            Logger.debug("🔄 Falling back to generated data")
            Logger.debug("🚴 Activity metrics for fallback generation:")
            Logger.debug("🚴   - Duration: \(activity.duration ?? 0)s")
            Logger.debug("🚴   - Distance: \(activity.distance ?? 0)m")
            Logger.debug("🚴   - Avg Power: \(activity.averagePower ?? 0)W")
            Logger.debug("🚴   - Avg HR: \(activity.averageHeartRate ?? 0)bpm")
            
            samples = ActivityDataTransformer.generateSamples(from: activity)
            
            Logger.debug("🚴 Generated \(samples.count) fallback samples after error")
            
            // Still try to enrich with generated data
            enrichedActivity = activity
        }
        
        isLoading = false
        
        Logger.debug("🚴 Final state:")
        Logger.debug("🚴   - Total samples: \(samples.count)")
        Logger.debug("🚴   - Is loading: \(isLoading)")
        Logger.debug("🚴   - Has error: \(error != nil)")
        Logger.debug("🚴 ================================================================")
    }
    
    /// Enrich activity summary with calculated values from stream data when API data is missing
    private func enrichActivityWithStreamData(activity: IntervalsActivity, samples: [WorkoutSample], profileManager: AthleteProfileManager) -> IntervalsActivity {
        Logger.debug("🔧 ========== ENRICHING ACTIVITY WITH STREAM DATA ==========")
        Logger.debug("🔧 Checking which fields need calculation...")
        
        var enriched = activity
        var changesCount = 0
        
        // Only enrich if we have samples
        guard !samples.isEmpty else {
            Logger.debug("🔧 No samples available for enrichment")
            Logger.debug("🔧 ================================================================")
            return activity
        }
        
        // Calculate duration from samples if missing
        if activity.duration == nil || activity.duration == 0 {
            if let lastSample = samples.last {
                enriched.duration = lastSample.time
                Logger.debug("🔧 ✅ Calculated duration: \(lastSample.time)s")
                changesCount += 1
            }
        }
        
        // Calculate average power if missing
        if activity.averagePower == nil || activity.averagePower == 0 {
            let powerSamples = samples.filter { $0.power > 0 }
            if !powerSamples.isEmpty {
                let avgPower = powerSamples.map { $0.power }.reduce(0, +) / Double(powerSamples.count)
                enriched.averagePower = avgPower
                Logger.debug("🔧 ✅ Calculated average power: \(Int(avgPower))W")
                changesCount += 1
            }
        }
        
        // Calculate average heart rate if missing
        if activity.averageHeartRate == nil || activity.averageHeartRate == 0 {
            let hrSamples = samples.filter { $0.heartRate > 0 }
            if !hrSamples.isEmpty {
                let avgHR = hrSamples.map { $0.heartRate }.reduce(0, +) / Double(hrSamples.count)
                enriched.averageHeartRate = avgHR
                Logger.debug("🔧 ✅ Calculated average heart rate: \(Int(avgHR))bpm")
                changesCount += 1
            }
        }
        
        // Calculate max heart rate if missing
        if activity.maxHeartRate == nil || activity.maxHeartRate == 0 {
            let hrSamples = samples.filter { $0.heartRate > 0 }
            if let maxHR = hrSamples.map({ $0.heartRate }).max() {
                enriched.maxHeartRate = maxHR
                Logger.debug("🔧 ✅ Calculated max heart rate: \(Int(maxHR))bpm")
                changesCount += 1
            }
        }
        
        // Calculate average speed if missing
        if activity.averageSpeed == nil || activity.averageSpeed == 0 {
            let speedSamples = samples.filter { $0.speed > 0 }
            if !speedSamples.isEmpty {
                let avgSpeed = speedSamples.map { $0.speed }.reduce(0, +) / Double(speedSamples.count)
                enriched.averageSpeed = avgSpeed
                Logger.debug("🔧 ✅ Calculated average speed: \(String(format: "%.1f", avgSpeed))km/h")
                changesCount += 1
            }
        }
        
        // Calculate max speed if missing
        if activity.maxSpeed == nil || activity.maxSpeed == 0 {
            let speedSamples = samples.filter { $0.speed > 0 }
            if let maxSpeed = speedSamples.map({ $0.speed }).max() {
                enriched.maxSpeed = maxSpeed
                Logger.debug("🔧 ✅ Calculated max speed: \(String(format: "%.1f", maxSpeed))km/h")
                changesCount += 1
            }
        }
        
        // Calculate average cadence if missing
        if activity.averageCadence == nil || activity.averageCadence == 0 {
            let cadenceSamples = samples.filter { $0.cadence > 0 }
            if !cadenceSamples.isEmpty {
                let avgCadence = cadenceSamples.map { $0.cadence }.reduce(0, +) / Double(cadenceSamples.count)
                enriched.averageCadence = avgCadence
                Logger.debug("🔧 ✅ Calculated average cadence: \(Int(avgCadence))rpm")
                changesCount += 1
            }
        }
        
        // Calculate elevation gain if missing
        if activity.elevationGain == nil || activity.elevationGain == 0 {
            let elevationSamples = samples.filter { $0.elevation > 0 }
            if !elevationSamples.isEmpty {
                let minElevation = elevationSamples.map { $0.elevation }.min() ?? 0
                let maxElevation = elevationSamples.map { $0.elevation }.max() ?? 0
                let elevationGain = maxElevation - minElevation
                if elevationGain > 0 {
                    enriched.elevationGain = elevationGain
                    Logger.debug("🔧 ✅ Calculated elevation gain: \(Int(elevationGain))m")
                    changesCount += 1
                }
            }
        }
        
        // Compute HR zone times from stream data using current adaptive zones
        let hrZoneTimes = computeHRZoneTimes(samples: samples, profileManager: profileManager)
        if !hrZoneTimes.isEmpty {
            enriched.icuHrZoneTimes = hrZoneTimes
            Logger.debug("🔧 ✅ Calculated HR zone times from stream data")
            changesCount += 1
        }
        
        // Compute Power zone times from stream data using current adaptive zones
        let powerZoneTimes = computePowerZoneTimes(samples: samples, profileManager: profileManager)
        if !powerZoneTimes.isEmpty {
            enriched.icuZoneTimes = powerZoneTimes
            Logger.debug("🔧 ✅ Calculated Power zone times from stream data")
            changesCount += 1
        }
        
        Logger.debug("🔧 Enrichment complete: \(changesCount) fields calculated from stream data")
        Logger.debug("🔧 ================================================================")
        
        return enriched
    }
    
    /// Compute time spent in each HR zone from stream samples using current adaptive zones
    private func computeHRZoneTimes(samples: [WorkoutSample], profileManager: AthleteProfileManager) -> [Double] {
        Logger.debug("💓 ========== COMPUTING HR ZONE TIMES FROM STREAM DATA ==========")
        
        // Get current adaptive HR zones
        guard let hrZones = profileManager.profile.hrZones, hrZones.count >= 2 else {
            Logger.debug("💓 ❌ No HR zones available from profile")
            Logger.debug("💓 ================================================================")
            return []
        }
        
        Logger.debug("💓 Current adaptive HR zones: \(hrZones.map { Int($0) })")
        
        // Filter samples with valid HR data
        let hrSamples = samples.filter { $0.heartRate > 0 }
        
        guard !hrSamples.isEmpty else {
            Logger.debug("💓 ❌ No HR samples available")
            Logger.debug("💓 ================================================================")
            return []
        }
        
        Logger.debug("💓 Total samples: \(samples.count), HR samples: \(hrSamples.count) (\(Int(Double(hrSamples.count)/Double(samples.count)*100))%)")
        
        // Calculate HR range in data
        let minHR = hrSamples.map { $0.heartRate }.min() ?? 0
        let maxHR = hrSamples.map { $0.heartRate }.max() ?? 0
        let avgHR = hrSamples.map { $0.heartRate }.reduce(0, +) / Double(hrSamples.count)
        
        Logger.debug("💓 HR Range: \(Int(minHR))-\(Int(maxHR)) bpm, Avg: \(Int(avgHR)) bpm")
        
        // Initialize zone time counters (7 zones)
        var zoneTimes = Array(repeating: 0.0, count: 7)
        
        // Count samples in each zone
        for sample in hrSamples {
            let hr = sample.heartRate
            
            // Determine which zone this HR falls into
            var zoneIndex = 0
            for i in 0..<(hrZones.count - 1) {
                if hr >= hrZones[i] && hr < hrZones[i + 1] {
                    zoneIndex = i
                    break
                }
                // Handle max HR case (>= last boundary)
                if i == hrZones.count - 2 && hr >= hrZones[i + 1] {
                    zoneIndex = i + 1  // Put in the highest zone (Zone 7)
                    break
                }
            }
            
            // Add 1 second to this zone (assumes 1 sample per second)
            if zoneIndex < zoneTimes.count {
                zoneTimes[zoneIndex] += 1.0
            }
        }
        
        // Log zone distribution
        Logger.debug("💓 ========== ZONE TIME DISTRIBUTION ==========")
        let totalTime = zoneTimes.reduce(0, +)
        for (index, time) in zoneTimes.enumerated() {
            if time > 0 {
                let percentage = (time / totalTime) * 100
                let minutes = Int(time / 60)
                let seconds = Int(time.truncatingRemainder(dividingBy: 60))
                let zoneName = hrZoneName(index)
                Logger.debug("💓 Zone \(index + 1) (\(zoneName)): \(minutes):\(String(format: "%02d", seconds)) (\(String(format: "%.1f", percentage))%)")
            }
        }
        Logger.debug("💓 Total time: \(Int(totalTime))s (\(Int(totalTime/60))min)")
        Logger.debug("💓 ================================================================")
        
        return zoneTimes
    }
    
    private func hrZoneName(_ index: Int) -> String {
        let names = ["Recovery", "Endurance", "Tempo", "Threshold", "VO2 Max", "Anaerobic", "Max"]
        return names[index % names.count]
    }
    
    /// Compute time spent in each Power zone from stream samples using current adaptive zones
    private func computePowerZoneTimes(samples: [WorkoutSample], profileManager: AthleteProfileManager) -> [Double] {
        Logger.debug("⚡️ ========== COMPUTING POWER ZONE TIMES FROM STREAM DATA ==========")
        
        // Get current adaptive power zones
        guard let powerZones = profileManager.profile.powerZones, powerZones.count >= 2 else {
            Logger.debug("⚡️ ❌ No power zones available from profile")
            Logger.debug("⚡️ ================================================================")
            return []
        }
        
        Logger.debug("⚡️ Current adaptive power zones: \(powerZones.map { Int($0) })")
        
        // Filter samples with valid power data
        let powerSamples = samples.filter { $0.power > 0 }
        
        guard !powerSamples.isEmpty else {
            Logger.debug("⚡️ ❌ No power samples available")
            Logger.debug("⚡️ ================================================================")
            return []
        }
        
        Logger.debug("⚡️ Total samples: \(samples.count), Power samples: \(powerSamples.count) (\(Int(Double(powerSamples.count)/Double(samples.count)*100))%)")
        
        // Calculate power range in data
        let minPower = powerSamples.map { $0.power }.min() ?? 0
        let maxPower = powerSamples.map { $0.power }.max() ?? 0
        let avgPower = powerSamples.map { $0.power }.reduce(0, +) / Double(powerSamples.count)
        
        Logger.debug("⚡️ Power Range: \(Int(minPower))-\(Int(maxPower)) W, Avg: \(Int(avgPower)) W")
        
        // Initialize zone time counters (7 zones)
        var zoneTimes = Array(repeating: 0.0, count: 7)
        
        // Count samples in each zone
        for sample in powerSamples {
            let power = sample.power
            
            // Determine which zone this power falls into
            var zoneIndex = 0
            for i in 0..<(powerZones.count - 1) {
                if power >= powerZones[i] && power < powerZones[i + 1] {
                    zoneIndex = i
                    break
                }
                // Handle max power case (>= last boundary)
                if i == powerZones.count - 2 && power >= powerZones[i + 1] {
                    zoneIndex = i + 1  // Put in the highest zone (Zone 7)
                    break
                }
            }
            
            // Add 1 second to this zone (assumes 1 sample per second)
            if zoneIndex < zoneTimes.count {
                zoneTimes[zoneIndex] += 1.0
            }
        }
        
        // Log zone distribution
        Logger.debug("⚡️ ========== ZONE TIME DISTRIBUTION ==========")
        let totalTime = zoneTimes.reduce(0, +)
        for (index, time) in zoneTimes.enumerated() {
            if time > 0 {
                let percentage = (time / totalTime) * 100
                let minutes = Int(time / 60)
                let seconds = Int(time.truncatingRemainder(dividingBy: 60))
                let zoneName = powerZoneName(index)
                Logger.debug("⚡️ Zone \(index + 1) (\(zoneName)): \(minutes):\(String(format: "%02d", seconds)) (\(String(format: "%.1f", percentage))%)")
            }
        }
        Logger.debug("⚡️ Total time: \(Int(totalTime))s (\(Int(totalTime/60))min)")
        Logger.debug("⚡️ ================================================================")
        
        return zoneTimes
    }
    
    private func powerZoneName(_ index: Int) -> String {
        let names = ["Active Recovery", "Endurance", "Tempo", "Threshold", "VO2 Max", "Anaerobic", "Neuromuscular"]
        return names[index % names.count]
    }
    
    // MARK: - Strava Data Loading
    
    private func loadStravaActivityData(activity: IntervalsActivity, profileManager: AthleteProfileManager) async {
        Logger.debug("🟠 ========== LOADING STRAVA ACTIVITY DATA ==========")
        
        // CRITICAL: Ensure zones are available before enriching activity
        await ensureZonesAvailable(profileManager: profileManager)
        
        // Extract numeric Strava ID from "strava_123456" format
        guard let stravaId = activity.id.components(separatedBy: "_").last else {
            Logger.error("Failed to extract Strava ID from: \(activity.id)")
            samples = ActivityDataTransformer.generateSamples(from: activity)
            isLoading = false
            return
        }
        
        Logger.debug("🟠 Strava Activity ID: \(stravaId)")
        
        // Try cache first (7-day TTL)
        let cacheKey = CacheKey.activityStreams(activityId: activity.id, source: "strava")
        if let cachedSamples: [WorkoutSample] = await CacheOrchestrator.shared.get(key: cacheKey, ttl: 604800) {
            Logger.debug("⚡ Using cached stream data (\(cachedSamples.count) samples)")
            samples = cachedSamples
            
            // Enrich activity with cached stream data
            var enriched = enrichActivityWithStreamData(activity: activity, samples: cachedSamples, profileManager: profileManager)
            enriched = await calculateTSSAndIF(for: enriched, profileManager: profileManager)
            
            enrichedActivity = enriched
            isLoading = false
            return
        }
        
        // Cache miss - fetch from API
        Logger.debug("📡 Cache miss - fetching from API...")
        
        do {
            // Fetch streams from backend API (which caches for 24 hours)
            Logger.debug("🟠 Fetching streams from VeloReady backend...")
            let streamsDict = try await VeloReadyAPIClient.shared.fetchActivityStreams(activityId: stravaId)
            
            Logger.debug("🟠 Received \(streamsDict.count) stream types from backend")
            
            // Convert backend response to StravaStream format
            let streams = streamsDict.map { (type, streamData) -> StravaStream in
                let data: StreamData
                switch streamData.data {
                case .simple(let values):
                    data = .simple(values)
                case .latlng(let coords):
                    data = .latlng(coords)
                }
                
                return StravaStream(
                    type: type,
                    data: data,
                    series_type: streamData.series_type,
                    original_size: streamData.original_size,
                    resolution: streamData.resolution
                )
            }
            
            Logger.debug("🟠 Converted to \(streams.count) stream objects")
            
            // Convert Strava streams to WorkoutSamples
            let workoutSamples = convertStravaStreamsToWorkoutSamples(streams: streams)
            
            Logger.debug("🟠 Converted to \(workoutSamples.count) workout samples")
            
            if !workoutSamples.isEmpty {
                samples = workoutSamples
                
                // Cache for future use
                let cacheKey = CacheKey.activityStreams(activityId: activity.id, source: "strava")
                await CacheOrchestrator.shared.set(key: cacheKey, value: workoutSamples, cachedAt: Date())
                
                // Enrich activity with stream data
                var enriched = enrichActivityWithStreamData(activity: activity, samples: workoutSamples, profileManager: profileManager)
                
                // Calculate TSS and IF with fallbacks for missing data
                Logger.debug("🟠 ========== TSS CALCULATION START ==========")
                Logger.debug("🟠 Activity Average Power: \(activity.averagePower?.description ?? "nil")")
                Logger.debug("🟠 Activity Normalized Power: \(activity.normalizedPower?.description ?? "nil")")
                Logger.debug("🟠 Profile FTP: \(profileManager.profile.ftp?.description ?? "nil")")
                
                var normalizedPower = activity.normalizedPower
                var ftp = profileManager.profile.ftp
                
                // Fallback 1: Estimate NP from average power if missing
                if normalizedPower == nil, let avgPower = activity.averagePower, avgPower > 0 {
                    normalizedPower = avgPower * 1.05 // Conservative NP estimate
                    Logger.debug("🟠 ✅ Estimated NP from average power: \(Int(normalizedPower!))W (avg power: \(Int(avgPower))W)")
                } else if normalizedPower != nil {
                    Logger.debug("🟠 ✅ Using activity normalized power: \(Int(normalizedPower!))W")
                } else {
                    Logger.warning("🟠 ❌ No power data available (avg or normalized)")
                }
                
                // Fallback 2: Try to get FTP from Strava athlete if not computed
                if ftp == nil || ftp == 0 {
                    Logger.debug("🟠 No FTP in profile, fetching from Strava...")
                    do {
                        // Use cache to avoid repeated API calls
                        // StravaAthleteCache deleted - use StravaAPIClient
                        let stravaAthlete = try await StravaAPIClient.shared.fetchAthlete()
                        if let stravaFTP = stravaAthlete.ftp, stravaFTP > 0 {
                            ftp = Double(stravaFTP)
                            Logger.debug("🟠 ✅ Using Strava FTP: \(Int(ftp!))W")
                        } else {
                            Logger.warning("🟠 ❌ Strava athlete has no FTP set")
                        }
                    } catch {
                        Logger.warning("🟠 ❌ Could not fetch Strava FTP: \(error)")
                    }
                    
                    // Fallback 3: Estimate FTP from this ride's power data
                    if (ftp == nil || ftp == 0), let np = normalizedPower, np > 50 {
                        // Conservative estimate: FTP is typically 15-20% higher than sustained power
                        // Using 1.15 multiplier for conservative estimate
                        let duration = activity.duration ?? 0
                        var multiplier = 1.15
                        
                        // Adjust multiplier based on ride duration
                        if duration >= 3600 { // 1+ hour
                            multiplier = 1.10 // Closer to FTP for long rides
                        } else if duration < 1800 { // < 30 min
                            multiplier = 1.25 // Likely well above FTP for short rides
                        }
                        
                        ftp = np * multiplier
                        Logger.warning("🟠 ⚠️ ESTIMATED FTP from ride data: \(Int(ftp!))W (NP: \(Int(np))W × \(String(format: "%.2f", multiplier)))")
                        Logger.warning("🟠 ⚠️ User should set actual FTP in Settings for accurate calculations")
                        
                        // Save estimated FTP to profile for zone generation
                        // Mark as 'intervals' source to indicate it's estimated/external
                        profileManager.profile.ftp = ftp
                        profileManager.profile.ftpSource = .intervals // Mark as estimated
                        profileManager.profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp!)
                        profileManager.save()
                        Logger.warning("🟠 💾 Saved estimated FTP to profile for zone generation")
                    }
                } else {
                    Logger.debug("🟠 ✅ Using profile FTP: \(Int(ftp!))W")
                }
                
                // Calculate TSS if we have both NP and FTP
                Logger.debug("🟠 Checking TSS calculation requirements:")
                Logger.debug("🟠   - NP available: \(normalizedPower != nil)")
                Logger.debug("🟠   - FTP available: \(ftp != nil && ftp! > 0)")
                Logger.debug("🟠   - NP > 0: \((normalizedPower ?? 0) > 0)")
                
                if let np = normalizedPower, let ftpValue = ftp, ftpValue > 0, np > 0 {
                    let intensityFactor = np / ftpValue
                    let duration = activity.duration ?? 0
                    let tss = (duration * np * intensityFactor) / (ftpValue * 36.0)
                    
                    Logger.debug("🟠 Calculated TSS: \(Int(tss)) (NP: \(Int(np))W, IF: \(String(format: "%.2f", intensityFactor)), FTP: \(Int(ftpValue))W)")
                    
                    // Create new activity with TSS and IF
                    enriched = IntervalsActivity(
                        id: enriched.id,
                        name: enriched.name,
                        description: enriched.description,
                        startDateLocal: enriched.startDateLocal,
                        type: enriched.type,
                        duration: enriched.duration,
                        distance: enriched.distance,
                        elevationGain: enriched.elevationGain,
                        averagePower: enriched.averagePower,
                        normalizedPower: np, // Use calculated/fallback NP
                        averageHeartRate: enriched.averageHeartRate,
                        maxHeartRate: enriched.maxHeartRate,
                        averageCadence: enriched.averageCadence,
                        averageSpeed: enriched.averageSpeed,
                        maxSpeed: enriched.maxSpeed,
                        calories: enriched.calories,
                        fileType: enriched.fileType,
                        tss: tss,
                        intensityFactor: intensityFactor,
                        atl: nil, // Will be set below from activity history
                        ctl: nil, // Will be set below from activity history
                        icuZoneTimes: enriched.icuZoneTimes,
                        icuHrZoneTimes: enriched.icuHrZoneTimes
                    )
                    
                    // Note: CTL/ATL calculation removed from here to prevent task cancellation
                    // TrainingLoadChart will calculate CTL/ATL independently with a stable task ID
                    
                    Logger.debug("🟠 ========== ENRICHED ACTIVITY CREATED ==========")
                    Logger.debug("🟠 Enriched TSS: \(enriched.tss?.description ?? "nil")")
                    Logger.debug("🟠 Enriched IF: \(enriched.intensityFactor?.description ?? "nil")")
                    Logger.debug("🟠 Enriched Power Zones: \(enriched.icuZoneTimes?.count ?? 0) zones")
                    Logger.debug("🟠 Enriched HR Zones: \(enriched.icuHrZoneTimes?.count ?? 0) zones")
                    Logger.debug("🟠 ================================================")
                } else {
                    Logger.warning("🟠 ❌ ========== TSS CALCULATION FAILED ==========")
                    Logger.warning("🟠 Cannot calculate TSS - missing data:")
                    Logger.warning("🟠   - NP: \(normalizedPower?.description ?? "nil")")
                    Logger.warning("🟠   - FTP: \(ftp?.description ?? "nil")")
                    Logger.warning("🟠   - FTP > 0: \(ftp != nil && ftp! > 0)")
                    Logger.warning("🟠 ================================================")
                }
                
                enrichedActivity = enriched
                Logger.debug("🟠 ✅ enrichedActivity SET on viewModel")
                Logger.debug("🟠 ✅ Successfully loaded Strava stream data")
            } else {
                Logger.warning("️ No stream data available, using generated data")
                samples = ActivityDataTransformer.generateSamples(from: activity)
            }
            
        } catch {
            Logger.error("Failed to load Strava streams: \(error)")
            Logger.error("Falling back to generated data")
            samples = ActivityDataTransformer.generateSamples(from: activity)
            enrichedActivity = activity
        }
        
        isLoading = false
        Logger.debug("🟠 ================================================================")
    }
    
    private func convertStravaStreamsToWorkoutSamples(streams: [StravaStream]) -> [WorkoutSample] {
        Logger.debug("🔄 Converting Strava streams to workout samples...")
        
        // Find the time stream to determine sample count
        guard let timeStream = streams.first(where: { $0.type == "time" }) else {
            Logger.error("No time stream found")
            return []
        }
        
        let times = timeStream.data.simpleData
        let sampleCount = times.count
        Logger.debug("🔄 Creating \(sampleCount) samples from streams")
        
        // Extract all stream data
        let watts = streams.first(where: { $0.type == "watts" })?.data.simpleData ?? []
        let heartrates = streams.first(where: { $0.type == "heartrate" })?.data.simpleData ?? []
        let cadences = streams.first(where: { $0.type == "cadence" })?.data.simpleData ?? []
        let altitudes = streams.first(where: { $0.type == "altitude" })?.data.simpleData ?? []
        let speeds = streams.first(where: { $0.type == "velocity_smooth" })?.data.simpleData ?? [] // m/s
        _ = streams.first(where: { $0.type == "distance" })?.data.simpleData ?? []
        let latlngs = streams.first(where: { $0.type == "latlng" })?.data.latlngData ?? []
        
        Logger.debug("🔄 Stream data available:")
        Logger.debug("  - latlng coordinates: \(latlngs.count)")
        
        var samples: [WorkoutSample] = []
        
        for i in 0..<sampleCount {
            // Extract lat/lng from nested array
            var latitude: Double? = nil
            var longitude: Double? = nil
            if i < latlngs.count && latlngs[i].count >= 2 {
                latitude = latlngs[i][0]  // First element is latitude
                longitude = latlngs[i][1]  // Second element is longitude
            }
            
            let sample = WorkoutSample(
                time: times[i],
                power: i < watts.count ? watts[i] : 0,
                heartRate: i < heartrates.count ? heartrates[i] : 0,
                speed: i < speeds.count ? speeds[i] * 3.6 : 0, // Convert m/s to km/h
                cadence: i < cadences.count ? cadences[i] : 0,
                elevation: i < altitudes.count ? altitudes[i] : 0,
                latitude: latitude,
                longitude: longitude
            )
            samples.append(sample)
        }
        
        Logger.debug("🔄 ✅ Converted \(samples.count) samples")
        Logger.debug("🔄 Sample quality:")
        Logger.debug("  - Power points: \(samples.filter { $0.power > 0 }.count)")
        Logger.debug("  - HR points: \(samples.filter { $0.heartRate > 0 }.count)")
        Logger.debug("  - Cadence points: \(samples.filter { $0.cadence > 0 }.count)")
        Logger.debug("  - Elevation points: \(samples.filter { $0.elevation > 0 }.count)")
        Logger.debug("  - GPS points: \(samples.filter { $0.latitude != nil && $0.longitude != nil }.count)")
        
        return samples
    }
    
    // CTL/ATL calculation removed - now handled by TrainingLoadChart to prevent task cancellation
    
    // Conversion now handled by unified ActivityConverter utility
    
    /// Ensure zones are available before enriching activities
    /// Generates default zones from FTP/maxHR if not already computed
    private func ensureZonesAvailable(profileManager: AthleteProfileManager) async {
        Logger.debug("🟠 ========== ENSURING ZONES AVAILABLE ==========")
        Logger.debug("🟠 Current Profile State:")
        Logger.debug("🟠   - FTP: \(profileManager.profile.ftp?.description ?? "nil")")
        Logger.debug("🟠   - Power Zones: \(profileManager.profile.powerZones?.count ?? 0) zones")
        Logger.debug("🟠   - Max HR: \(profileManager.profile.maxHR?.description ?? "nil")")
        Logger.debug("🟠   - HR Zones: \(profileManager.profile.hrZones?.count ?? 0) zones")
        
        var needsSave = false
        
        // Ensure FTP and power zones
        if profileManager.profile.ftp == nil || profileManager.profile.ftp == 0 {
            Logger.debug("🟠 No FTP found, trying to get from Strava...")
            // Try to get FTP from Strava
            do {
                // StravaAthleteCache deleted - use StravaAPIClient
                let stravaAthlete = try await StravaAPIClient.shared.fetchAthlete()
                if let stravaFTP = stravaAthlete.ftp, stravaFTP > 0 {
                    Logger.debug("🟠 ✅ Setting FTP from Strava: \(stravaFTP)W")
                    profileManager.profile.ftp = Double(stravaFTP)
                    profileManager.profile.ftpSource = .intervals
                    needsSave = true
                } else {
                    Logger.warning("🟠 ❌ Strava athlete has no FTP set - will estimate")
                }
            } catch {
                Logger.warning("🟠 ❌ Could not fetch Strava FTP: \(error) - will estimate")
            }
        } else {
            Logger.debug("🟠 ✅ FTP already exists: \(Int(profileManager.profile.ftp!))W")
        }
        
        // Generate power zones if missing
        if (profileManager.profile.powerZones == nil || profileManager.profile.powerZones!.isEmpty),
           let ftp = profileManager.profile.ftp, ftp > 0 {
            Logger.debug("🟠 ✅ Generating power zones from FTP: \(Int(ftp))W")
            profileManager.profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp)
            Logger.debug("🟠 Generated zones: \(profileManager.profile.powerZones!.map { Int($0) })")
            needsSave = true
        } else if profileManager.profile.powerZones != nil {
            Logger.debug("🟠 ✅ Power zones already exist: \(profileManager.profile.powerZones!.count) zones")
        } else {
            Logger.warning("🟠 ❌ Cannot generate power zones - no FTP available")
        }
        
        // Generate HR zones if missing (use default maxHR if needed)
        if (profileManager.profile.hrZones == nil || profileManager.profile.hrZones!.isEmpty) {
            let maxHR = profileManager.profile.maxHR ?? 190.0 // Use default if not set
            Logger.debug("🟠 ✅ Generating HR zones from maxHR: \(Int(maxHR))bpm")
            profileManager.profile.hrZones = AthleteProfileManager.generateHRZones(maxHR: maxHR)
            Logger.debug("🟠 Generated zones: \(profileManager.profile.hrZones!.map { Int($0) })")
            if profileManager.profile.maxHR == nil {
                profileManager.profile.maxHR = maxHR
            }
            needsSave = true
        } else {
            Logger.debug("🟠 ✅ HR zones already exist: \(profileManager.profile.hrZones!.count) zones")
        }
        
        if needsSave {
            Logger.debug("🟠 Saving profile with updated zones/FTP")
            profileManager.save()
        }
        
        Logger.debug("🟠 Final Profile State:")
        Logger.debug("🟠   - FTP: \(profileManager.profile.ftp?.description ?? "nil")")
        Logger.debug("🟠   - Power Zones: \(profileManager.profile.powerZones?.count ?? 0) zones")
        Logger.debug("🟠   - HR Zones: \(profileManager.profile.hrZones?.count ?? 0) zones")
        Logger.debug("🟠 ================================================")
    }
    
    /// Calculate TSS and IF for an activity
    /// This is extracted so it can be called for both cached and fresh data
    private func calculateTSSAndIF(for activity: IntervalsActivity, profileManager: AthleteProfileManager) async -> IntervalsActivity {
        Logger.debug("🟠 ========== TSS CALCULATION START ==========")
        Logger.debug("🟠 Activity Average Power: \(activity.averagePower?.description ?? "nil")")
        Logger.debug("🟠 Activity Normalized Power: \(activity.normalizedPower?.description ?? "nil")")
        Logger.debug("🟠 Profile FTP: \(profileManager.profile.ftp?.description ?? "nil")")
        
        var normalizedPower = activity.normalizedPower
        var ftp = profileManager.profile.ftp
        
        // Fallback 1: Estimate NP from average power if missing
        if normalizedPower == nil, let avgPower = activity.averagePower, avgPower > 0 {
            normalizedPower = avgPower * 1.05 // Conservative NP estimate
            Logger.debug("🟠 ✅ Estimated NP from average power: \(Int(normalizedPower!))W (avg power: \(Int(avgPower))W)")
        } else if normalizedPower != nil {
            Logger.debug("🟠 ✅ Using activity normalized power: \(Int(normalizedPower!))W")
        } else {
            Logger.warning("🟠 ❌ No power data available (avg or normalized)")
        }
        
        // Fallback 2: Try to get FTP from Strava athlete if not computed
        if ftp == nil || ftp == 0 {
            Logger.debug("🟠 No FTP in profile, fetching from Strava...")
            do {
                // Use cache to avoid repeated API calls
                // StravaAthleteCache deleted - use StravaAPIClient
                let stravaAthlete = try await StravaAPIClient.shared.fetchAthlete()
                if let stravaFTP = stravaAthlete.ftp, stravaFTP > 0 {
                    ftp = Double(stravaFTP)
                    Logger.debug("🟠 ✅ Using Strava FTP: \(Int(ftp!))W")
                } else {
                    Logger.warning("🟠 ❌ Strava athlete has no FTP set")
                }
            } catch {
                Logger.warning("🟠 ❌ Could not fetch Strava FTP: \(error)")
            }
            
            // Fallback 3: Estimate FTP from this ride's power data
            if (ftp == nil || ftp == 0), let np = normalizedPower, np > 50 {
                let duration = activity.duration ?? 0
                var multiplier = 1.15
                
                // Adjust multiplier based on ride duration
                if duration >= 3600 { // 1+ hour
                    multiplier = 1.10 // Closer to FTP for long rides
                } else if duration < 1800 { // < 30 min
                    multiplier = 1.25 // Likely well above FTP for short rides
                }
                
                ftp = np * multiplier
                Logger.warning("🟠 ⚠️ ESTIMATED FTP from ride data: \(Int(ftp!))W (NP: \(Int(np))W × \(String(format: "%.2f", multiplier)))")
                Logger.warning("🟠 ⚠️ User should set actual FTP in Settings for accurate calculations")
                
                // Save estimated FTP to profile for zone generation
                profileManager.profile.ftp = ftp
                profileManager.profile.ftpSource = .intervals // Mark as estimated
                profileManager.profile.powerZones = AthleteProfileManager.generatePowerZones(ftp: ftp!)
                profileManager.save()
                Logger.warning("🟠 💾 Saved estimated FTP to profile for zone generation")
            }
        } else {
            Logger.debug("🟠 ✅ Using profile FTP: \(Int(ftp!))W")
        }
        
        // Calculate TSS if we have both NP and FTP
        Logger.debug("🟠 Checking TSS calculation requirements:")
        Logger.debug("🟠   - NP available: \(normalizedPower != nil)")
        Logger.debug("🟠   - FTP available: \(ftp != nil && ftp! > 0)")
        Logger.debug("🟠   - NP > 0: \((normalizedPower ?? 0) > 0)")
        
        if let np = normalizedPower, let ftpValue = ftp, ftpValue > 0, np > 0 {
            let intensityFactor = np / ftpValue
            let duration = activity.duration ?? 0
            let tss = (duration * np * intensityFactor) / (ftpValue * 36.0)
            
            Logger.debug("🟠 Calculated TSS: \(Int(tss)) (NP: \(Int(np))W, IF: \(String(format: "%.2f", intensityFactor)), FTP: \(Int(ftpValue))W)")
            
            // Create enriched activity with TSS and IF
            let enriched = IntervalsActivity(
                id: activity.id,
                name: activity.name,
                description: activity.description,
                startDateLocal: activity.startDateLocal,
                type: activity.type,
                source: activity.source,
                duration: activity.duration,
                distance: activity.distance,
                elevationGain: activity.elevationGain,
                averagePower: activity.averagePower,
                normalizedPower: activity.normalizedPower,
                averageHeartRate: activity.averageHeartRate,
                maxHeartRate: activity.maxHeartRate,
                averageCadence: activity.averageCadence,
                averageSpeed: activity.averageSpeed,
                maxSpeed: activity.maxSpeed,
                calories: activity.calories,
                fileType: activity.fileType,
                tss: tss,
                intensityFactor: intensityFactor,
                atl: nil, // Will be set by TrainingLoadChart
                ctl: nil, // Will be set by TrainingLoadChart
                icuZoneTimes: activity.icuZoneTimes,
                icuHrZoneTimes: activity.icuHrZoneTimes
            )
            
            Logger.debug("🟠 ========== ENRICHED ACTIVITY CREATED ==========")
            Logger.debug("🟠 Enriched TSS: \(enriched.tss?.description ?? "nil")")
            Logger.debug("🟠 Enriched IF: \(enriched.intensityFactor?.description ?? "nil")")
            Logger.debug("🟠 ================================================")
            
            return enriched
        } else {
            Logger.warning("🟠 ❌ ========== TSS CALCULATION FAILED ==========")
            Logger.warning("🟠 Cannot calculate TSS - missing data:")
            Logger.warning("🟠   - NP: \(normalizedPower?.description ?? "nil")")
            Logger.warning("🟠   - FTP: \(ftp?.description ?? "nil")")
            Logger.warning("🟠   - FTP > 0: \(ftp != nil && ftp! > 0)")
            Logger.warning("🟠 ================================================")
            return activity
        }
    }
}
