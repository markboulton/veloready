import SwiftUI
import HealthKit

/// Shared activity row view used in both Today and Activities list
struct SharedActivityRowView: View {
    let activity: UnifiedActivity
    @State private var showingRPESheet = false
    @State private var hasRPE = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Type Icon
            Image(systemName: activityIcon)
                .font(.title3)
                .foregroundColor(activityColor)
                .frame(width: 24, height: 24)
            
            // Activity Details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(formatSmartDate(activity.startDate))
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
                    .foregroundColor(hasRPE ? ColorScale.greenAccent : ColorScale.gray400)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(hasRPE ? ColorScale.greenAccent.opacity(0.1) : ColorScale.gray100)
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
    
    private func formatSmartDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return "Today at \(timeFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return "Yesterday at \(timeFormatter.string(from: date))"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM yyyy 'at' HH:mm"
            return dateFormatter.string(from: date)
        }
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
    
    private var activityColor: Color {
        switch activity.type {
        case .cycling:
            return ColorScale.blueAccent
        case .running:
            return ColorScale.redAccent
        case .swimming:
            return ColorScale.cyanAccent
        case .walking:
            return ColorScale.greenAccent
        case .hiking:
            return ColorScale.amberAccent
        case .strength:
            return ColorScale.purpleAccent
        case .yoga:
            return ColorScale.pinkAccent
        case .hiit:
            return ColorScale.redAccent
        case .other:
            return ColorScale.gray400
        }
    }
}
