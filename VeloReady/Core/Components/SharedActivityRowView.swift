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
                // Activity name
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // Date/time with icon and optional location
                HStack(spacing: 6) {
                    Image(systemName: activityIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatSmartDate(activity.startDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Navigation chevron (shown when in NavigationLink)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(0.5)
            
            // Compact RPE indicator for strength workouts
            if shouldShowRPEButton {
                Button(action: { showingRPESheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: hasRPE ? "checkmark.circle.fill" : "plus.circle")
                            .font(.caption)
                        Text(hasRPE ? "RPE" : "Add")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(hasRPE ? ColorScale.greenAccent : ColorScale.gray600)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(hasRPE ? ColorScale.greenAccent.opacity(0.1) : ColorScale.gray200)
                    .cornerRadius(12)
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
    
    // MARK: - Activity Icon & Color
    
    private var activityIcon: String {
        switch activity.type {
        case .cycling:
            return "bicycle"
        case .running:
            return "figure.run"
        case .swimming:
            return "figure.pool.swim"
        case .walking:
            return "figure.walk"
        case .hiking:
            return "figure.hiking"
        case .strength:
            return "dumbbell.fill"
        case .yoga:
            return "figure.yoga"
        case .hiit:
            return "flame.fill"
        case .other:
            return "figure.mixed.cardio"
        }
    }
    
}
