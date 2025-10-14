import SwiftUI
import HealthKit

/// Shared activity row view used in both Today and Activities list
struct SharedActivityRowView: View {
    let activity: UnifiedActivity
    @State private var showingRPESheet = false
    @State private var hasRPE = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(formatDate(activity.startDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let duration = activity.duration {
                        Text("•").foregroundColor(.secondary)
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let distance = activity.distance {
                        Text("•").foregroundColor(.secondary)
                        Text(formatDistance(distance))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Add details button for strength workouts
            if shouldShowRPEButton {
                Button(action: {
                    showingRPESheet = true
                }) {
                    Text("Add details")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorScale.blueAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ColorScale.blueAccent, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onAppear {
            checkRPEStatus()
        }
        .sheet(isPresented: $showingRPESheet) {
            if let workout = activity.healthKitWorkout {
                RPEInputSheet(workout: workout) {
                    hasRPE = true
                }
            }
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.1f km", km)
    }
    
    // MARK: - RPE Helpers
    
    private var shouldShowRPEButton: Bool {
        guard let workout = activity.healthKitWorkout else { return false }
        return workout.workoutActivityType == .traditionalStrengthTraining ||
               workout.workoutActivityType == .functionalStrengthTraining
    }
    
    private func checkRPEStatus() {
        guard let workout = activity.healthKitWorkout else { return }
        hasRPE = RPEStorageService.shared.hasRPE(for: workout)
    }
}
