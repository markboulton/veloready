import SwiftUI

/// Debug view for ML infrastructure testing
struct MLDebugView: View {
    @StateObject private var mlService = MLTrainingDataService.shared
    @StateObject private var mlRegistry = MLModelRegistry.shared
    
    @State private var isProcessing = false
    @State private var statusMessage = ""
    @State private var dataQualityReport: MLDataQualityReport?
    
    var body: some View {
        List {
            Section("ML Infrastructure Status") {
                statusRow(label: "ML Enabled", value: mlRegistry.isMLEnabled ? "✅ Yes" : "❌ No")
                statusRow(label: "Current Model", value: mlRegistry.currentModelVersion ?? "None")
                statusRow(label: "Training Data", value: "\(mlService.trainingDataCount) days")
                statusRow(label: "Last Processing", value: mlService.lastProcessingDate?.formatted() ?? "Never")
            }
            
            if let report = dataQualityReport {
                Section("Data Quality") {
                    statusRow(label: "Total Days", value: "\(report.totalDays)")
                    statusRow(label: "Valid Days", value: "\(report.validDays)")
                    statusRow(label: "Completeness", value: report.completenessPercentage)
                    statusRow(label: "Sufficient Data", value: report.hasSufficientData ? "✅ Yes" : "❌ No")
                    
                    if !report.missingFeatures.isEmpty {
                        Text("Missing Features:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(report.missingFeatures, id: \.self) { feature in
                            Text("• \(feature)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Actions") {
                Button(action: { Task { await processHistoricalData() } }) {
                    HStack {
                        Text("Process Historical Data (90 days)")
                        Spacer()
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isProcessing)
                
                Button(action: { Task { await checkDataQuality() } }) {
                    Text("Check Data Quality")
                }
                .disabled(isProcessing)
                
                Button(action: { mlRegistry.setMLEnabled(!mlRegistry.isMLEnabled) }) {
                    Text(mlRegistry.isMLEnabled ? "Disable ML" : "Enable ML")
                }
            }
            
            if !statusMessage.isEmpty {
                Section("Status") {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Phase 1 Info") {
                Text("This is Phase 1: ML Infrastructure Setup")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("✅ Historical data aggregation from Core Data, HealthKit, Intervals.icu, and Strava")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("✅ Feature engineering (rolling averages, deltas, trends)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("✅ Training data storage in Core Data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("✅ Model registry for version management")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("ML Debug")
        .onAppear {
            Task {
                await checkDataQuality()
            }
        }
    }
    
    private func statusRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    private func processHistoricalData() async {
        isProcessing = true
        statusMessage = "Processing historical data..."
        
        await mlService.processHistoricalData(days: 90)
        
        statusMessage = "✅ Processing complete! \(mlService.trainingDataCount) valid days extracted."
        isProcessing = false
        
        // Refresh data quality report
        await checkDataQuality()
    }
    
    private func checkDataQuality() async {
        let report = await mlService.getDataQualityReport()
        dataQualityReport = report
        
        if report.validDays > 0 {
            statusMessage = "Data quality: \(report.completenessPercentage) complete, \(report.validDays)/\(report.totalDays) valid days"
        } else {
            statusMessage = "No training data available. Click 'Process Historical Data' to start."
        }
    }
}

#Preview {
    NavigationStack {
        MLDebugView()
    }
}
