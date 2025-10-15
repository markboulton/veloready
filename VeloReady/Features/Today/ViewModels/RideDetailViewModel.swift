import Foundation
import SwiftUI

@MainActor
class RideDetailViewModel: ObservableObject {
    @Published private(set) var samples: [WorkoutSample] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var enrichedActivity: IntervalsActivity?
    
    func loadActivityData(activity: IntervalsActivity, apiClient: IntervalsAPIClient, profileManager: AthleteProfileManager) async {
        print("🚴 ========== RIDE DETAIL VIEW MODEL: LOAD ACTIVITY DATA ==========")
        print("🚴 Activity ID: \(activity.id)")
        print("🚴 Activity Name: \(activity.name ?? "Unknown")")
        print("🚴 Activity Type: \(activity.type ?? "Unknown")")
        print("🚴 Start Date: \(activity.startDateLocal)")
        
        isLoading = true
        error = nil
        
        // Check if this is a Strava activity (ID starts with "strava_")
        if activity.id.hasPrefix("strava_") {
            print("🚴 Detected Strava activity, fetching from Strava API...")
            await loadStravaActivityData(activity: activity, profileManager: profileManager)
            return
        }
        
        do {
            print("🚴 Attempting to fetch time-series data from Intervals.icu API...")
            // Fetch time-series data from API
            let streamData = try await apiClient.fetchActivityStreams(activityId: activity.id)
            
            print("🚴 API Response received: \(streamData.count) samples")
            
            if streamData.isEmpty {
                print("⚠️ API returned empty data, falling back to generated data")
                print("🚴 Activity metrics for fallback generation:")
                print("🚴   - Duration: \(activity.duration ?? 0)s")
                print("🚴   - Distance: \(activity.distance ?? 0)m")
                print("🚴   - Avg Power: \(activity.averagePower ?? 0)W")
                print("🚴   - Avg HR: \(activity.averageHeartRate ?? 0)bpm")
                print("🚴   - Avg Speed: \(activity.averageSpeed ?? 0)km/h")
                
                samples = ActivityDataTransformer.generateSamples(from: activity)
                
                print("🚴 Generated \(samples.count) fallback samples")
            } else {
                print("✅ Successfully loaded \(streamData.count) data points from API")
                
                // Analyze the data we received
                let samplesWithPower = streamData.filter { $0.power > 0 }.count
                let samplesWithHR = streamData.filter { $0.heartRate > 0 }.count
                let samplesWithSpeed = streamData.filter { $0.speed > 0 }.count
                let samplesWithCadence = streamData.filter { $0.cadence > 0 }.count
                let samplesWithGPS = streamData.filter { $0.latitude != nil && $0.longitude != nil }.count
                
                print("🚴 Data Quality Analysis:")
                print("🚴   - Samples with Power: \(samplesWithPower)/\(streamData.count) (\(Int(Double(samplesWithPower)/Double(streamData.count)*100))%)")
                print("🚴   - Samples with HR: \(samplesWithHR)/\(streamData.count) (\(Int(Double(samplesWithHR)/Double(streamData.count)*100))%)")
                print("🚴   - Samples with Speed: \(samplesWithSpeed)/\(streamData.count) (\(Int(Double(samplesWithSpeed)/Double(streamData.count)*100))%)")
                print("🚴   - Samples with Cadence: \(samplesWithCadence)/\(streamData.count) (\(Int(Double(samplesWithCadence)/Double(streamData.count)*100))%)")
                print("🚴   - Samples with GPS: \(samplesWithGPS)/\(streamData.count) (\(Int(Double(samplesWithGPS)/Double(streamData.count)*100))%)")
                
                // Calculate averages from actual data
                if samplesWithPower > 0 {
                    let avgPower = streamData.filter { $0.power > 0 }.map { $0.power }.reduce(0, +) / Double(samplesWithPower)
                    print("🚴   - Calculated Avg Power: \(Int(avgPower))W (Activity says: \(activity.averagePower ?? 0)W)")
                }
                if samplesWithHR > 0 {
                    let avgHR = streamData.filter { $0.heartRate > 0 }.map { $0.heartRate }.reduce(0, +) / Double(samplesWithHR)
                    print("🚴   - Calculated Avg HR: \(Int(avgHR))bpm (Activity says: \(activity.averageHeartRate ?? 0)bpm)")
                }
                if samplesWithSpeed > 0 {
                    let avgSpeed = streamData.filter { $0.speed > 0 }.map { $0.speed }.reduce(0, +) / Double(samplesWithSpeed)
                    print("🚴   - Calculated Avg Speed: \(String(format: "%.1f", avgSpeed))km/h (Activity says: \(activity.averageSpeed ?? 0)km/h)")
                }
                
                samples = streamData
                
                // Enrich activity with calculated data if summary is missing values
                enrichedActivity = enrichActivityWithStreamData(activity: activity, samples: streamData, profileManager: profileManager)
            }
            
        } catch {
            print("❌ Failed to load activity data: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            self.error = error.localizedDescription
            
            // Fall back to generated data
            print("🔄 Falling back to generated data")
            print("🚴 Activity metrics for fallback generation:")
            print("🚴   - Duration: \(activity.duration ?? 0)s")
            print("🚴   - Distance: \(activity.distance ?? 0)m")
            print("🚴   - Avg Power: \(activity.averagePower ?? 0)W")
            print("🚴   - Avg HR: \(activity.averageHeartRate ?? 0)bpm")
            
            samples = ActivityDataTransformer.generateSamples(from: activity)
            
            print("🚴 Generated \(samples.count) fallback samples after error")
            
            // Still try to enrich with generated data
            enrichedActivity = activity
        }
        
        isLoading = false
        
        print("🚴 Final state:")
        print("🚴   - Total samples: \(samples.count)")
        print("🚴   - Is loading: \(isLoading)")
        print("🚴   - Has error: \(error != nil)")
        print("🚴 ================================================================")
    }
    
    /// Enrich activity summary with calculated values from stream data when API data is missing
    private func enrichActivityWithStreamData(activity: IntervalsActivity, samples: [WorkoutSample], profileManager: AthleteProfileManager) -> IntervalsActivity {
        print("🔧 ========== ENRICHING ACTIVITY WITH STREAM DATA ==========")
        print("🔧 Checking which fields need calculation...")
        
        var enriched = activity
        var changesCount = 0
        
        // Only enrich if we have samples
        guard !samples.isEmpty else {
            print("🔧 No samples available for enrichment")
            print("🔧 ================================================================")
            return activity
        }
        
        // Calculate duration from samples if missing
        if activity.duration == nil || activity.duration == 0 {
            if let lastSample = samples.last {
                enriched.duration = lastSample.time
                print("🔧 ✅ Calculated duration: \(lastSample.time)s")
                changesCount += 1
            }
        }
        
        // Calculate average power if missing
        if activity.averagePower == nil || activity.averagePower == 0 {
            let powerSamples = samples.filter { $0.power > 0 }
            if !powerSamples.isEmpty {
                let avgPower = powerSamples.map { $0.power }.reduce(0, +) / Double(powerSamples.count)
                enriched.averagePower = avgPower
                print("🔧 ✅ Calculated average power: \(Int(avgPower))W")
                changesCount += 1
            }
        }
        
        // Calculate average heart rate if missing
        if activity.averageHeartRate == nil || activity.averageHeartRate == 0 {
            let hrSamples = samples.filter { $0.heartRate > 0 }
            if !hrSamples.isEmpty {
                let avgHR = hrSamples.map { $0.heartRate }.reduce(0, +) / Double(hrSamples.count)
                enriched.averageHeartRate = avgHR
                print("🔧 ✅ Calculated average heart rate: \(Int(avgHR))bpm")
                changesCount += 1
            }
        }
        
        // Calculate max heart rate if missing
        if activity.maxHeartRate == nil || activity.maxHeartRate == 0 {
            let hrSamples = samples.filter { $0.heartRate > 0 }
            if let maxHR = hrSamples.map({ $0.heartRate }).max() {
                enriched.maxHeartRate = maxHR
                print("🔧 ✅ Calculated max heart rate: \(Int(maxHR))bpm")
                changesCount += 1
            }
        }
        
        // Calculate average speed if missing
        if activity.averageSpeed == nil || activity.averageSpeed == 0 {
            let speedSamples = samples.filter { $0.speed > 0 }
            if !speedSamples.isEmpty {
                let avgSpeed = speedSamples.map { $0.speed }.reduce(0, +) / Double(speedSamples.count)
                enriched.averageSpeed = avgSpeed
                print("🔧 ✅ Calculated average speed: \(String(format: "%.1f", avgSpeed))km/h")
                changesCount += 1
            }
        }
        
        // Calculate max speed if missing
        if activity.maxSpeed == nil || activity.maxSpeed == 0 {
            let speedSamples = samples.filter { $0.speed > 0 }
            if let maxSpeed = speedSamples.map({ $0.speed }).max() {
                enriched.maxSpeed = maxSpeed
                print("🔧 ✅ Calculated max speed: \(String(format: "%.1f", maxSpeed))km/h")
                changesCount += 1
            }
        }
        
        // Calculate average cadence if missing
        if activity.averageCadence == nil || activity.averageCadence == 0 {
            let cadenceSamples = samples.filter { $0.cadence > 0 }
            if !cadenceSamples.isEmpty {
                let avgCadence = cadenceSamples.map { $0.cadence }.reduce(0, +) / Double(cadenceSamples.count)
                enriched.averageCadence = avgCadence
                print("🔧 ✅ Calculated average cadence: \(Int(avgCadence))rpm")
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
                    print("🔧 ✅ Calculated elevation gain: \(Int(elevationGain))m")
                    changesCount += 1
                }
            }
        }
        
        // Compute HR zone times from stream data using current adaptive zones
        let hrZoneTimes = computeHRZoneTimes(samples: samples, profileManager: profileManager)
        if !hrZoneTimes.isEmpty {
            enriched.icuHrZoneTimes = hrZoneTimes
            print("🔧 ✅ Calculated HR zone times from stream data")
            changesCount += 1
        }
        
        // Compute Power zone times from stream data using current adaptive zones
        let powerZoneTimes = computePowerZoneTimes(samples: samples, profileManager: profileManager)
        if !powerZoneTimes.isEmpty {
            enriched.icuZoneTimes = powerZoneTimes
            print("🔧 ✅ Calculated Power zone times from stream data")
            changesCount += 1
        }
        
        print("🔧 Enrichment complete: \(changesCount) fields calculated from stream data")
        print("🔧 ================================================================")
        
        return enriched
    }
    
    /// Compute time spent in each HR zone from stream samples using current adaptive zones
    private func computeHRZoneTimes(samples: [WorkoutSample], profileManager: AthleteProfileManager) -> [Double] {
        print("💓 ========== COMPUTING HR ZONE TIMES FROM STREAM DATA ==========")
        
        // Get current adaptive HR zones
        guard let hrZones = profileManager.profile.hrZones, hrZones.count >= 2 else {
            print("💓 ❌ No HR zones available from profile")
            print("💓 ================================================================")
            return []
        }
        
        print("💓 Current adaptive HR zones: \(hrZones.map { Int($0) })")
        
        // Filter samples with valid HR data
        let hrSamples = samples.filter { $0.heartRate > 0 }
        
        guard !hrSamples.isEmpty else {
            print("💓 ❌ No HR samples available")
            print("💓 ================================================================")
            return []
        }
        
        print("💓 Total samples: \(samples.count), HR samples: \(hrSamples.count) (\(Int(Double(hrSamples.count)/Double(samples.count)*100))%)")
        
        // Calculate HR range in data
        let minHR = hrSamples.map { $0.heartRate }.min() ?? 0
        let maxHR = hrSamples.map { $0.heartRate }.max() ?? 0
        let avgHR = hrSamples.map { $0.heartRate }.reduce(0, +) / Double(hrSamples.count)
        
        print("💓 HR Range: \(Int(minHR))-\(Int(maxHR)) bpm, Avg: \(Int(avgHR)) bpm")
        
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
        print("💓 ========== ZONE TIME DISTRIBUTION ==========")
        let totalTime = zoneTimes.reduce(0, +)
        for (index, time) in zoneTimes.enumerated() {
            if time > 0 {
                let percentage = (time / totalTime) * 100
                let minutes = Int(time / 60)
                let seconds = Int(time.truncatingRemainder(dividingBy: 60))
                let zoneName = hrZoneName(index)
                print("💓 Zone \(index + 1) (\(zoneName)): \(minutes):\(String(format: "%02d", seconds)) (\(String(format: "%.1f", percentage))%)")
            }
        }
        print("💓 Total time: \(Int(totalTime))s (\(Int(totalTime/60))min)")
        print("💓 ================================================================")
        
        return zoneTimes
    }
    
    private func hrZoneName(_ index: Int) -> String {
        let names = ["Recovery", "Endurance", "Tempo", "Threshold", "VO2 Max", "Anaerobic", "Max"]
        return names[index % names.count]
    }
    
    /// Compute time spent in each Power zone from stream samples using current adaptive zones
    private func computePowerZoneTimes(samples: [WorkoutSample], profileManager: AthleteProfileManager) -> [Double] {
        print("⚡️ ========== COMPUTING POWER ZONE TIMES FROM STREAM DATA ==========")
        
        // Get current adaptive power zones
        guard let powerZones = profileManager.profile.powerZones, powerZones.count >= 2 else {
            print("⚡️ ❌ No power zones available from profile")
            print("⚡️ ================================================================")
            return []
        }
        
        print("⚡️ Current adaptive power zones: \(powerZones.map { Int($0) })")
        
        // Filter samples with valid power data
        let powerSamples = samples.filter { $0.power > 0 }
        
        guard !powerSamples.isEmpty else {
            print("⚡️ ❌ No power samples available")
            print("⚡️ ================================================================")
            return []
        }
        
        print("⚡️ Total samples: \(samples.count), Power samples: \(powerSamples.count) (\(Int(Double(powerSamples.count)/Double(samples.count)*100))%)")
        
        // Calculate power range in data
        let minPower = powerSamples.map { $0.power }.min() ?? 0
        let maxPower = powerSamples.map { $0.power }.max() ?? 0
        let avgPower = powerSamples.map { $0.power }.reduce(0, +) / Double(powerSamples.count)
        
        print("⚡️ Power Range: \(Int(minPower))-\(Int(maxPower)) W, Avg: \(Int(avgPower)) W")
        
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
        print("⚡️ ========== ZONE TIME DISTRIBUTION ==========")
        let totalTime = zoneTimes.reduce(0, +)
        for (index, time) in zoneTimes.enumerated() {
            if time > 0 {
                let percentage = (time / totalTime) * 100
                let minutes = Int(time / 60)
                let seconds = Int(time.truncatingRemainder(dividingBy: 60))
                let zoneName = powerZoneName(index)
                print("⚡️ Zone \(index + 1) (\(zoneName)): \(minutes):\(String(format: "%02d", seconds)) (\(String(format: "%.1f", percentage))%)")
            }
        }
        print("⚡️ Total time: \(Int(totalTime))s (\(Int(totalTime/60))min)")
        print("⚡️ ================================================================")
        
        return zoneTimes
    }
    
    private func powerZoneName(_ index: Int) -> String {
        let names = ["Active Recovery", "Endurance", "Tempo", "Threshold", "VO2 Max", "Anaerobic", "Neuromuscular"]
        return names[index % names.count]
    }
    
    // MARK: - Strava Data Loading
    
    private func loadStravaActivityData(activity: IntervalsActivity, profileManager: AthleteProfileManager) async {
        print("🟠 ========== LOADING STRAVA ACTIVITY DATA ==========")
        
        // Extract numeric Strava ID from "strava_123456" format
        guard let stravaId = activity.id.components(separatedBy: "_").last else {
            print("❌ Failed to extract Strava ID from: \(activity.id)")
            samples = ActivityDataTransformer.generateSamples(from: activity)
            isLoading = false
            return
        }
        
        print("🟠 Strava Activity ID: \(stravaId)")
        
        do {
            // Fetch streams from Strava API
            print("🟠 Fetching streams from Strava API...")
            let streams = try await StravaAPIClient.shared.fetchActivityStreams(
                id: stravaId,
                types: ["time", "latlng", "distance", "altitude", "velocity_smooth", "heartrate", "cadence", "watts", "temp", "moving", "grade_smooth"]
            )
            
            print("🟠 Received \(streams.count) stream types from Strava")
            
            // Convert Strava streams to WorkoutSamples
            let workoutSamples = convertStravaStreamsToWorkoutSamples(streams: streams)
            
            print("🟠 Converted to \(workoutSamples.count) workout samples")
            
            if !workoutSamples.isEmpty {
                samples = workoutSamples
                
                // Enrich activity with stream data
                var enriched = enrichActivityWithStreamData(activity: activity, samples: workoutSamples, profileManager: profileManager)
                
                // Calculate TSS and IF from weighted_average_watts (Strava's normalized power)
                if let normalizedPower = activity.normalizedPower, let ftp = profileManager.profile.ftp, ftp > 0 {
                    let intensityFactor = normalizedPower / ftp
                    let duration = activity.duration ?? 0
                    let tss = (duration * normalizedPower * intensityFactor) / (ftp * 36.0)
                    
                    print("🟠 Calculated TSS: \(Int(tss)) (NP: \(Int(normalizedPower))W, IF: \(String(format: "%.2f", intensityFactor)), FTP: \(Int(ftp))W)")
                    
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
                        normalizedPower: enriched.normalizedPower,
                        averageHeartRate: enriched.averageHeartRate,
                        maxHeartRate: enriched.maxHeartRate,
                        averageCadence: enriched.averageCadence,
                        averageSpeed: enriched.averageSpeed,
                        maxSpeed: enriched.maxSpeed,
                        calories: enriched.calories,
                        fileType: enriched.fileType,
                        tss: tss,
                        intensityFactor: intensityFactor,
                        atl: enriched.atl,
                        ctl: enriched.ctl,
                        icuZoneTimes: enriched.icuZoneTimes,
                        icuHrZoneTimes: enriched.icuHrZoneTimes
                    )
                }
                
                enrichedActivity = enriched
                print("🟠 ✅ Successfully loaded Strava stream data")
            } else {
                print("⚠️ No stream data available, using generated data")
                samples = ActivityDataTransformer.generateSamples(from: activity)
            }
            
        } catch {
            print("❌ Failed to load Strava streams: \(error)")
            print("❌ Falling back to generated data")
            samples = ActivityDataTransformer.generateSamples(from: activity)
            enrichedActivity = activity
        }
        
        isLoading = false
        print("🟠 ================================================================")
    }
    
    private func convertStravaStreamsToWorkoutSamples(streams: [StravaStream]) -> [WorkoutSample] {
        print("🔄 Converting Strava streams to workout samples...")
        
        // Find the time stream to determine sample count
        guard let timeStream = streams.first(where: { $0.type == "time" }) else {
            print("❌ No time stream found")
            return []
        }
        
        let times = timeStream.data.simpleData
        let sampleCount = times.count
        print("🔄 Creating \(sampleCount) samples from streams")
        
        // Extract all stream data
        let watts = streams.first(where: { $0.type == "watts" })?.data.simpleData ?? []
        let heartrates = streams.first(where: { $0.type == "heartrate" })?.data.simpleData ?? []
        let cadences = streams.first(where: { $0.type == "cadence" })?.data.simpleData ?? []
        let altitudes = streams.first(where: { $0.type == "altitude" })?.data.simpleData ?? []
        let speeds = streams.first(where: { $0.type == "velocity_smooth" })?.data.simpleData ?? [] // m/s
        _ = streams.first(where: { $0.type == "distance" })?.data.simpleData ?? []
        let latlngs = streams.first(where: { $0.type == "latlng" })?.data.latlngData ?? []
        
        print("🔄 Stream data available:")
        print("  - latlng coordinates: \(latlngs.count)")
        
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
        
        print("🔄 ✅ Converted \(samples.count) samples")
        print("🔄 Sample quality:")
        print("  - Power points: \(samples.filter { $0.power > 0 }.count)")
        print("  - HR points: \(samples.filter { $0.heartRate > 0 }.count)")
        print("  - Cadence points: \(samples.filter { $0.cadence > 0 }.count)")
        print("  - Elevation points: \(samples.filter { $0.elevation > 0 }.count)")
        print("  - GPS points: \(samples.filter { $0.latitude != nil && $0.longitude != nil }.count)")
        
        return samples
    }
}
