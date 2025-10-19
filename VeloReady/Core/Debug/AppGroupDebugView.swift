import SwiftUI

/// Debug view to test App Group functionality
struct AppGroupDebugView: View {
    @State private var testResult = "Not tested yet"
    @State private var recoveryScore: Int?
    @State private var recoveryBand: String?
    
    var body: some View {
        List {
            Section("App Group Test") {
                Button("Test Write to App Group") {
                    testWrite()
                }
                
                Button("Test Read from App Group") {
                    testRead()
                }
                
                Text(testResult)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Current Recovery Data") {
                if let score = recoveryScore {
                    HStack {
                        Text("Score")
                        Spacer()
                        Text("\(score)")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let band = recoveryBand {
                    HStack {
                        Text("Band")
                        Spacer()
                        Text(band)
                            .foregroundColor(.secondary)
                    }
                }
                
                if recoveryScore == nil && recoveryBand == nil {
                    Text("No data in App Group")
                        .foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("App Group Debug")
        .onAppear {
            testRead()
        }
    }
    
    private func testWrite() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") else {
            testResult = "❌ FAILED: Could not access App Group"
            return
        }
        
        // Write test data
        sharedDefaults.set(99, forKey: "cachedRecoveryScore")
        sharedDefaults.set("Test", forKey: "cachedRecoveryBand")
        sharedDefaults.set(true, forKey: "cachedRecoveryIsPersonalized")
        
        testResult = "✅ SUCCESS: Wrote test data to App Group"
        
        // Read it back
        testRead()
    }
    
    private func testRead() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") else {
            testResult = "❌ FAILED: Could not access App Group"
            return
        }
        
        let score = sharedDefaults.integer(forKey: "cachedRecoveryScore")
        let band = sharedDefaults.string(forKey: "cachedRecoveryBand")
        
        if score > 0 {
            recoveryScore = score
            recoveryBand = band
            testResult = "✅ SUCCESS: Read data from App Group"
        } else {
            recoveryScore = nil
            recoveryBand = nil
            testResult = "⚠️ WARNING: App Group accessible but no data found"
        }
    }
}

#Preview {
    NavigationStack {
        AppGroupDebugView()
    }
}
