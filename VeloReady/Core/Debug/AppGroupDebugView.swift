import SwiftUI

/// Debug view to test App Group functionality
struct AppGroupDebugView: View {
    @State private var testResult = CommonContent.Debug.statusInitial
    @State private var recoveryScore: Int?
    @State private var recoveryBand: String?
    
    var body: some View {
        List {
            Section {
                Button(CommonContent.Debug.buttonWrite) {
                    testWrite()
                }
                
                Button(CommonContent.Debug.buttonRead) {
                    testRead()
                }
                
                Text(testResult)
                    .font(TypeScale.font(size: TypeScale.xs))
                    .foregroundColor(ColorPalette.labelSecondary)
            }
            
            Section(CommonContent.Debug.sectionData) {
                if let score = recoveryScore {
                    HStack {
                        Text(CommonContent.Debug.labelScore)
                        Spacer()
                        Text("\(score)")
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                }
                
                if let band = recoveryBand {
                    HStack {
                        Text(CommonContent.Debug.labelBand)
                        Spacer()
                        Text(band)
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                }
                
                if recoveryScore == nil && recoveryBand == nil {
                    Text(CommonContent.Debug.messageNoData)
                        .foregroundColor(ColorPalette.warning)
                }
            }
        }
        .navigationTitle(CommonContent.Debug.title)
        .onAppear {
            testRead()
        }
    }
    
    private func testWrite() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") else {
            testResult = CommonContent.Debug.statusFailed
            return
        }
        
        // Write test data
        sharedDefaults.set(99, forKey: "cachedRecoveryScore")
        sharedDefaults.set("Test", forKey: "cachedRecoveryBand")
        sharedDefaults.set(true, forKey: "cachedRecoveryIsPersonalized")
        
        testResult = CommonContent.Debug.statusWriteSuccess
        
        // Read it back
        testRead()
    }
    
    private func testRead() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") else {
            testResult = CommonContent.Debug.statusFailed
            return
        }
        
        let score = sharedDefaults.integer(forKey: "cachedRecoveryScore")
        let band = sharedDefaults.string(forKey: "cachedRecoveryBand")
        
        if score > 0 {
            recoveryScore = score
            recoveryBand = band
            testResult = CommonContent.Debug.statusReadSuccess
        } else {
            recoveryScore = nil
            recoveryBand = nil
            testResult = CommonContent.Debug.statusNoData
        }
    }
}

#Preview {
    NavigationStack {
        AppGroupDebugView()
    }
}
