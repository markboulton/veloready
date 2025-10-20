import SwiftUI

/// Debug view to test App Group functionality
struct AppGroupDebugView: View {
    @State private var testResult = DebugContent.AppGroup.statusInitial
    @State private var recoveryScore: Int?
    @State private var recoveryBand: String?
    
    var body: some View {
        List {
            Section(DebugContent.AppGroup.sectionTest) {
                Button(DebugContent.AppGroup.buttonWrite) {
                    testWrite()
                }
                
                Button(DebugContent.AppGroup.buttonRead) {
                    testRead()
                }
                
                Text(testResult)
                    .font(TypeScale.font(size: TypeScale.xs))
                    .foregroundColor(ColorPalette.labelSecondary)
            }
            
            Section(DebugContent.AppGroup.sectionData) {
                if let score = recoveryScore {
                    HStack {
                        Text(DebugContent.AppGroup.labelScore)
                        Spacer()
                        Text("\(score)")
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                }
                
                if let band = recoveryBand {
                    HStack {
                        Text(DebugContent.AppGroup.labelBand)
                        Spacer()
                        Text(band)
                            .foregroundColor(ColorPalette.labelSecondary)
                    }
                }
                
                if recoveryScore == nil && recoveryBand == nil {
                    Text(DebugContent.AppGroup.messageNoData)
                        .foregroundColor(ColorPalette.warning)
                }
            }
        }
        .navigationTitle(DebugContent.AppGroup.title)
        .onAppear {
            testRead()
        }
    }
    
    private func testWrite() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") else {
            testResult = DebugContent.AppGroup.statusFailed
            return
        }
        
        // Write test data
        sharedDefaults.set(99, forKey: "cachedRecoveryScore")
        sharedDefaults.set("Test", forKey: "cachedRecoveryBand")
        sharedDefaults.set(true, forKey: "cachedRecoveryIsPersonalized")
        
        testResult = DebugContent.AppGroup.statusWriteSuccess
        
        // Read it back
        testRead()
    }
    
    private func testRead() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") else {
            testResult = DebugContent.AppGroup.statusFailed
            return
        }
        
        let score = sharedDefaults.integer(forKey: "cachedRecoveryScore")
        let band = sharedDefaults.string(forKey: "cachedRecoveryBand")
        
        if score > 0 {
            recoveryScore = score
            recoveryBand = band
            testResult = DebugContent.AppGroup.statusReadSuccess
        } else {
            recoveryScore = nil
            recoveryBand = nil
            testResult = DebugContent.AppGroup.statusNoData
        }
    }
}

#Preview {
    NavigationStack {
        AppGroupDebugView()
    }
}
