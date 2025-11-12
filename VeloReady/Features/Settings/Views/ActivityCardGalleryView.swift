import SwiftUI
import HealthKit

#if DEBUG
/// Gallery view showcasing all ActivityCard variations
struct ActivityCardGalleryView: View {
    @State private var outdoorRideMapImage: UIImage?
    @State private var walkMapImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Section Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Card Gallery")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("All activity card variations with different metadata")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.sm)
                
                // Outdoor Ride
                sectionHeader("Outdoor Ride", subtitle: "With map, location, and full metrics")
                
                ActivityCard(
                    activity: UnifiedActivity(
                        from: Activity(
                            id: "1",
                            name: "Morning Ride",
                            description: "Great ride through the hills",
                            startDateLocal: "2025-10-22T08:30:00",
                            type: "Ride",
                            duration: 5400, // 1h 30m
                            distance: 45200, // 45.2 km
                            elevationGain: 650,
                            averagePower: 185,
                            normalizedPower: 195,
                            averageHeartRate: 145,
                            maxHeartRate: 172,
                            averageCadence: 88,
                            averageSpeed: 28.5,
                            maxSpeed: 52.3,
                            calories: 1250,
                            fileType: "fit",
                            tss: 87.0,
                            intensityFactor: 0.82,
                            atl: 65.0,
                            ctl: 75.0,
                            icuZoneTimes: [600, 1800, 2400, 600, 0, 0, 0],
                            icuHrZoneTimes: [900, 2700, 1500, 300, 0, 0, 0]
                        )
                    ),
                    showChevron: true,
                    onTap: { print("Tapped outdoor ride") },
                    mockMapImage: outdoorRideMapImage
                )
                
                // Indoor/Virtual Ride
                sectionHeader("Indoor Ride", subtitle: "Virtual ride, no map, indoor icon")
                
                ActivityCard(
                    activity: UnifiedActivity(
                        from: Activity(
                            id: "2",
                            name: "2 x 20 Threshold",
                            description: "Indoor trainer session",
                            startDateLocal: "2025-10-21T18:00:00",
                            type: "VirtualRide",
                            duration: 3600, // 1h
                            distance: 1200, // 1.2 km (indoor)
                            elevationGain: 0,
                            averagePower: 210,
                            normalizedPower: 220,
                            averageHeartRate: 158,
                            maxHeartRate: 175,
                            averageCadence: 92,
                            averageSpeed: 0.33,
                            maxSpeed: 0.5,
                            calories: 950,
                            fileType: "fit",
                            tss: 95.0,
                            intensityFactor: 0.92,
                            atl: 68.0,
                            ctl: 78.0,
                            icuZoneTimes: [300, 600, 1200, 1500, 0, 0, 0],
                            icuHrZoneTimes: [600, 1200, 1200, 600, 0, 0, 0]
                        )
                    ),
                    showChevron: true,
                    onTap: { print("Tapped indoor ride") }
                )
                
                // Strength Workout - No RPE
                sectionHeader("Strength Workout", subtitle: "With RPE badge (Add CTA)")
                
                ActivityCard(
                    activity: UnifiedActivity(
                        from: HKWorkout(
                            activityType: .traditionalStrengthTraining,
                            start: Date().addingTimeInterval(-3600),
                            end: Date(),
                            duration: 3600,
                            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 350),
                            totalDistance: nil,
                            metadata: nil
                        )
                    ),
                    showChevron: true,
                    onTap: { print("Tapped strength workout") }
                )
                
                // Walking Workout
                sectionHeader("Walking Workout", subtitle: "Distance-based activity")
                
                ActivityCard(
                    activity: UnifiedActivity(
                        from: HKWorkout(
                            activityType: .walking,
                            start: Date().addingTimeInterval(-1800),
                            end: Date(),
                            duration: 1800, // 30 min
                            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 120),
                            totalDistance: HKQuantity(unit: .meter(), doubleValue: 2400), // 2.4 km
                            metadata: nil
                        )
                    ),
                    showChevron: true,
                    onTap: { print("Tapped walking workout") },
                    mockMapImage: walkMapImage
                )
                
                // Short Ride (different metrics)
                sectionHeader("Short Ride", subtitle: "Quick session with lower TSS")
                
                ActivityCard(
                    activity: UnifiedActivity(
                        from: Activity(
                            id: "3",
                            name: "Recovery Spin",
                            description: "Easy recovery ride",
                            startDateLocal: "2025-10-20T16:00:00",
                            type: "Ride",
                            duration: 1800, // 30 min
                            distance: 12500, // 12.5 km
                            elevationGain: 80,
                            averagePower: 120,
                            normalizedPower: 125,
                            averageHeartRate: 115,
                            maxHeartRate: 135,
                            averageCadence: 75,
                            averageSpeed: 25.0,
                            maxSpeed: 32.0,
                            calories: 280,
                            fileType: "fit",
                            tss: 18.0,
                            intensityFactor: 0.52,
                            atl: 62.0,
                            ctl: 72.0,
                            icuZoneTimes: [1200, 600, 0, 0, 0, 0, 0],
                            icuHrZoneTimes: [1500, 300, 0, 0, 0, 0, 0]
                        )
                    ),
                    showChevron: true,
                    onTap: { print("Tapped recovery ride") }
                )
                
                // Bottom spacing
                Color.clear
                    .frame(height: Spacing.xl)
            }
        }
        .background(Color.background.primary)
        .navigationTitle("Activity Cards")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMockMaps()
        }
    }
    
    private func loadMockMaps() {
        Task {
            // Generate outdoor ride map
            let rideCoords = MockMapGenerator.mockRideRoute()
            if let rideMap = await MockMapGenerator.shared.generateMockMap(
                center: rideCoords[rideCoords.count / 2],
                routeCoordinates: rideCoords
            ) {
                await MainActor.run {
                    self.outdoorRideMapImage = rideMap
                }
            }
            
            // Generate walk map
            let walkCoords = MockMapGenerator.mockWalkRoute()
            if let walkMap = await MockMapGenerator.shared.generateMockMap(
                center: walkCoords[walkCoords.count / 2],
                routeCoordinates: walkCoords
            ) {
                await MainActor.run {
                    self.walkMapImage = walkMap
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        ActivityCardGalleryView()
    }
}
#endif
