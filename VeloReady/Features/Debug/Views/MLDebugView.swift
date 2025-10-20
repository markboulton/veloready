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
                statusRow(label: DebugContent.ML.mlEnabled, value: mlRegistry.isMLEnabled ? DebugContent.MLDebugExtended.mlEnabledCheck : DebugContent.MLDebugExtended.mlDisabledCheck)
                statusRow(label: DebugContent.ML.currentModel, value: mlRegistry.currentModelVersion ?? DebugContent.ML.none)
                statusRow(label: DebugContent.ML.trainingData, value: "\(mlService.trainingDataCount) " + DebugContent.MLDebugExtended.daysCount)
                statusRow(label: DebugContent.ML.lastProcessing, value: mlService.lastProcessingDate?.formatted() ?? DebugContent.ML.never)
            }
            
            if let report = dataQualityReport {
                Section(DebugContent.ML.dataQuality) {
                    statusRow(label: DebugContent.MLDebugExtended.totalDays, value: "\(report.totalDays)")
                    statusRow(label: DebugContent.MLDebugExtended.validDays, value: "\(report.validDays)")
                    statusRow(label: DebugContent.MLDebugExtended.completeness, value: report.completenessPercentage)
                    statusRow(label: DebugContent.MLDebugExtended.sufficientData, value: report.hasSufficientData ? DebugContent.MLDebugExtended.yesCheck : DebugContent.MLDebugExtended.noCheck)
                    
                    if !report.missingFeatures.isEmpty {
                        Text(DebugContent.ML.missingFeatures)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(report.missingFeatures, id: \.self) { feature in
                            Text(DebugContent.MLDebugExtended.missingFeaturePrefix + feature)
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
            
            Section(DebugContent.MLDebugExtended.week1Testing) {
                Button(action: { Task { await testTrainingPipeline() } }) {
                    HStack {
                        Text(DebugContent.MLDebugExtended.testTrainingPipeline)
                            .fontWeight(.semibold)
                        Spacer()
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isProcessing)
                
                Text(DebugContent.MLDebugExtended.testDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !statusMessage.isEmpty {
                Section(DebugContent.MLDebugExtended.statusHeader) {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(DebugContent.MLDebugExtended.phase1Info) {
                Text(DebugContent.MLDebugExtended.phase1Description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(DebugContent.MLDebugExtended.historicalDataCheck)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(DebugContent.MLDebugExtended.featureEngineeringCheck)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(DebugContent.MLDebugExtended.trainingDataStorageCheck)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(DebugContent.MLDebugExtended.modelRegistryCheck)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(DebugContent.Navigation.mlDebug)
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
