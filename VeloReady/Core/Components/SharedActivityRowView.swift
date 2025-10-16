import SwiftUI
import HealthKit

/// Shared activity row view used in both Today and Activities list
struct SharedActivityRowView: View {
    let activity: UnifiedActivity
    @State private var showingRPESheet = false
    @State private var hasRPE = false
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Activity Details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Activity name
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // Date/time with icon and optional location
                HStack(spacing: Spacing.sm - 2) {
                    Image(systemName: activity.type.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatSmartDate(activity.startDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Compact RPE indicator for strength workouts
            if shouldShowRPEButton {
                RPEBadge(hasRPE: hasRPE) {
                    showingRPESheet = true
                }
            }
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, Spacing.sm)
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
    
    // Static formatters for performance - DateFormatter creation is expensive
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy 'at' HH:mm"
        return formatter
    }()
    
    private static let calendar = Calendar.current
    
    private func formatSmartDate(_ date: Date) -> String {
        if Self.calendar.isDateInToday(date) {
            return "Today at \(Self.timeFormatter.string(from: date))"
        } else if Self.calendar.isDateInYesterday(date) {
            return "Yesterday at \(Self.timeFormatter.string(from: date))"
        } else {
            return Self.dateTimeFormatter.string(from: date)
        }
    }
    
    // MARK: - RPE Helpers
    
    private var shouldShowRPEButton: Bool {
        guard let workout = activity.healthKitWorkout else { return false }
        return workout.workoutActivityType == .traditionalStrengthTraining ||
               workout.workoutActivityType == .functionalStrengthTraining
    }
    
    private func checkRPEStatus() {
        guard let workout = activity.healthKitWorkout else { return }
        hasRPE = WorkoutMetadataService.shared.hasMetadata(for: workout)
    }
    
}
