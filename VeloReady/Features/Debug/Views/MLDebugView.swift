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
            Section(DebugContent.ML.infrastructureStatus) {
                statusRow(label: DebugContent.ML.mlEnabled, value: mlRegistry.isMLEnabled ? "✅ Yes" : "❌ No")
                statusRow(label: DebugContent.ML.currentModel, value: mlRegistry.currentModelVersion ?? DebugContent.ML.none)
                statusRow(label: DebugContent.ML.trainingData, value: "\(mlService.trainingDataCount) days")
                statusRow(label: DebugContent.ML.lastProcessing, value: mlService.lastProcessingDate?.formatted() ?? DebugContent.ML.never)
            }
            
            if let report = dataQualityReport {
                Section(DebugContent.ML.dataQuality) {
                    statusRow(label: "Total Days", value: "\(report.totalDays)")
                    statusRow(label: "Valid Days", value: "\(report.validDays)")
                    statusRow(label: "Completeness", value: report.completenessPercentage)
                    statusRow(label: "Sufficient Data", value: report.hasSufficientData ? "✅ Yes" : "❌ No")
                    
                    if !report.missingFeatures.isEmpty {
                        Text(DebugContent.ML.missingFeatures)
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
            
            Section(DebugContent.ML.actions) {
                Button(action: { Task { await processHistoricalData() } }) {
                    HStack {
                        Text(DebugContent.ML.processHistorical)
                        Spacer()
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isProcessing)
                
                Button(action: { Task { await checkDataQuality() } }) {
                    Text(DebugContent.ML.checkQuality)
                }
                .disabled(isProcessing)
                
                Button(action: { mlRegistry.setMLEnabled(!mlRegistry.isMLEnabled) }) {
                    Text(mlRegistry.isMLEnabled ? DebugContent.ML.disable : DebugContent.ML.enable)
                }
            }
            
            Section("🧪 Week 1 Testing") {
                Button(action: { Task { await testTrainingPipeline() } }) {
                    HStack {
                        Text("🚀 Test Training Pipeline")
                            .fontWeight(.semibold)
                        Spacer()
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isProcessing)
                
                Text("Tests dataset builder + model trainer with current data")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    
    private func testTrainingPipeline() async {
        isProcessing = true
        statusMessage = "🧪 Testing training pipeline with current data..."
        
        #if os(macOS)
        do {
            let trainer = MLModelTrainer()
            try await trainer.testTrainingPipeline()
            
            statusMessage = "✅ Pipeline test PASSED! Check logs for details."
        } catch {
            statusMessage = "❌ Pipeline test FAILED: \(error.localizedDescription)"
            Logger.error("Pipeline test failed: \(error)")
        }
        #else
        statusMessage = "⚠️ ML training is only available on macOS"
        #endif
        
        isProcessing = false
    }
}

#Preview {
    NavigationStack {
        MLDebugView()
    }
}
