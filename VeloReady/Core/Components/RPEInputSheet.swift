import SwiftUI
import HealthKit

/// Sheet for inputting RPE (Rate of Perceived Exertion) for a workout
struct RPEInputSheet: View {
    let workout: HKWorkout
    @Environment(\.dismiss) private var dismiss
    @State private var rpeValue: Double
    @State private var isSaving = false
    
    var onSave: (() -> Void)?
    
    init(workout: HKWorkout, onSave: (() -> Void)? = nil) {
        self.workout = workout
        self.onSave = onSave
        
        // Initialize with existing RPE or default to 6.5
        let existingRPE = RPEStorageService.shared.getRPE(for: workout) ?? 6.5
        _rpeValue = State(initialValue: existingRPE)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Rate Your Effort")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("How hard did this workout feel?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                
                // RPE Display
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", rpeValue))
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text(rpeDescription)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                
                // Slider
                VStack(spacing: 16) {
                    Slider(value: $rpeValue, in: 1...10, step: 0.5)
                        .accentColor(.blue)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("1 - Very Light")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("10 - Maximum")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal, 8)
                
                // RPE Guide
                VStack(alignment: .leading, spacing: 12) {
                    rpeGuideRow(range: "1-2", label: "Very Light", description: "Minimal effort")
                    rpeGuideRow(range: "3-4", label: "Light", description: "Easy, can talk freely")
                    rpeGuideRow(range: "5-6", label: "Moderate", description: "Working, can still talk")
                    rpeGuideRow(range: "7-8", label: "Hard", description: "Difficult, short answers")
                    rpeGuideRow(range: "9-10", label: "Maximum", description: "Can't sustain long")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button(action: saveRPE) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark")
                            Text("Save RPE")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isSaving)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("RPE Rating")
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
    
    private func rpeGuideRow(range: String, label: String, description: String) -> some View {
        HStack(spacing: 12) {
            Text(range)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(width: 36, alignment: .leading)
            
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 70, alignment: .leading)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
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
    
    private func saveRPE() {
        isSaving = true
        
        // Save RPE
        RPEStorageService.shared.saveRPE(rpeValue, for: workout)
        
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

#Preview {
    RPEInputSheet(workout: HKWorkout(
        activityType: .traditionalStrengthTraining,
        start: Date(),
        end: Date().addingTimeInterval(1800)
    ))
}
