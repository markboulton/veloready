import SwiftUI
import HealthKit

/// Sheet for inputting RPE (Rate of Perceived Exertion) and muscle groups for a workout
struct RPEInputSheet: View {
    let workout: HKWorkout
    @Environment(\.dismiss) private var dismiss
    @State private var rpeValue: Double
    @State private var selectedMuscleGroups: Set<MuscleGroup> = []
    @State private var isSaving = false
    
    var onSave: (() -> Void)?
    
    init(workout: HKWorkout, onSave: (() -> Void)? = nil) {
        self.workout = workout
        self.onSave = onSave
        
        // Initialize with existing data or defaults
        let existingRPE = WorkoutMetadataService.shared.getRPE(for: workout) ?? 6.5
        let existingMuscleGroups = WorkoutMetadataService.shared.getMuscleGroups(for: workout) ?? []
        
        print("🔵 RPEInputSheet init - Workout UUID: \(workout.uuid)")
        print("🔵 Existing RPE: \(existingRPE)")
        print("🔵 Existing muscle groups: \(existingMuscleGroups.map { $0.rawValue })")
        
        _rpeValue = State(initialValue: existingRPE)
        _selectedMuscleGroups = State(initialValue: Set(existingMuscleGroups))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Workout Details")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.text.primary)
                        
                        Text("Rate your effort and select muscle groups trained")
                            .font(.subheadline)
                            .foregroundColor(Color.text.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    
                    // RPE Display
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", rpeValue))
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(Color.text.primary)
                            .padding(.top, 36)
                        
                        Text(rpeDescription)
                            .font(.headline)
                            .foregroundColor(Color.text.secondary)
                    }
                    .padding(.vertical, 16)
                
                // Slider with custom styling
                VStack(spacing: 16) {
                    Text("Effort Level")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Slider(value: $rpeValue, in: 1...10, step: 0.5)
                        .tint(Color.button.primary)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("1 - Very Light")
                            .font(.caption)
                            .foregroundColor(Color.text.secondary)
                        Spacer()
                        Text("10 - Maximum")
                            .font(.caption)
                            .foregroundColor(Color.text.secondary)
                    }
                    .padding(.horizontal)
                    
                    // RPE Guide (moved below slider)
                    VStack(alignment: .leading, spacing: 8) {
                        rpeGuideRow(range: "1-2", label: "Very Light", description: "Minimal effort")
                        rpeGuideRow(range: "3-4", label: "Light", description: "Easy, can talk freely")
                        rpeGuideRow(range: "5-6", label: "Moderate", description: "Working, can still talk")
                        rpeGuideRow(range: "7-8", label: "Hard", description: "Difficult, short answers")
                        rpeGuideRow(range: "9-10", label: "Maximum", description: "Can't sustain long")
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal, 8)
                
                // Muscle Groups Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Muscle Groups (Optional)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(muscleGroupOptions, id: \.self) { group in
                            MuscleGroupButton(
                                group: group,
                                isSelected: selectedMuscleGroups.contains(group)
                            ) {
                                if selectedMuscleGroups.contains(group) {
                                    selectedMuscleGroups.remove(group)
                                } else {
                                    selectedMuscleGroups.insert(group)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Workout Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Workout Type (Optional)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(workoutTypeOptions, id: \.self) { group in
                            MuscleGroupButton(
                                group: group,
                                isSelected: selectedMuscleGroups.contains(group)
                            ) {
                                if selectedMuscleGroups.contains(group) {
                                    selectedMuscleGroups.remove(group)
                                } else {
                                    selectedMuscleGroups.insert(group)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                    // Save Button
                    Button(action: saveDetails) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark")
                                Text("Save Details")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.button.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Computed properties for organized muscle group lists
    private var muscleGroupOptions: [MuscleGroup] {
        [.legs, .back, .chest, .shoulders, .arms, .core]
    }
    
    private var workoutTypeOptions: [MuscleGroup] {
        [.push, .pull, .fullBody, .conditioning]
    }
    
    private func rpeGuideRow(range: String, label: String, description: String) -> some View {
        HStack(spacing: 12) {
            Text(range)
                .font(.smcaption)
                .fontWeight(.semibold)
                .foregroundColor(Color.text.primary)
                .frame(width: 36, alignment: .leading)
            
            Text(label)
                .font(.smcaption)
                .fontWeight(.semibold)
                .foregroundColor(Color.text.primary)
                .frame(width: 70, alignment: .leading)
            
            Text(description)
                .font(.smcaption)
                .foregroundColor(Color.text.secondary)
            
            Spacer()
        }
    }
    
    private var rpeDescription: String {
        switch rpeValue {
        case 1..<2.5:
            return "Very Light"
        case 2.5..<4.5:
            return "Light"
        case 4.5..<6.5:
            return "Moderate"
        case 6.5..<8.5:
            return "Hard"
        default:
            return "Maximum"
        }
    }
    
    private func saveDetails() {
        isSaving = true
        
        print("🟢 RPEInputSheet saveDetails called")
        print("🟢 RPE: \(rpeValue)")
        print("🟢 Selected muscle groups count: \(selectedMuscleGroups.count)")
        print("🟢 Selected muscle groups: \(selectedMuscleGroups.map { $0.rawValue })")
        print("🟢 Workout UUID: \(workout.uuid)")
        
        // Save to new Core Data service
        WorkoutMetadataService.shared.saveMetadata(
            for: workout,
            rpe: rpeValue,
            muscleGroups: selectedMuscleGroups.isEmpty ? nil : Array(selectedMuscleGroups),
            isEccentricFocused: nil // TODO: Add UI for this
        )
        
        print("🟢 Save completed, refreshing strain score...")
        
        // Trigger strain score refresh
        Task {
            await StrainScoreService.shared.calculateStrainScore()
            
            await MainActor.run {
                isSaving = false
                onSave?()
                dismiss()
            }
        }
    }
}

// MARK: - Muscle Group Button

private struct MuscleGroupButton: View {
    let group: MuscleGroup
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(group.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? Color.button.primary : Color.text.primary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.button.primary.opacity(0.1) : ColorScale.gray100)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.button.primary : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RPEInputSheet(workout: HKWorkout(
        activityType: .traditionalStrengthTraining,
        start: Date(),
        end: Date().addingTimeInterval(1800)
    ))
}
