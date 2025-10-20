//
//  DebugContent.swift
//  VeloReady
//
//  Content strings for debug views and tools
//

import Foundation

enum DebugContent {
    
    // MARK: - App Group Debug
    
    enum AppGroup {
        static let title = "App Group Debug"
        static let sectionTest = "App Group Test"
        static let sectionData = "Current Recovery Data"
        
        static let buttonWrite = "Test Write to App Group"
        static let buttonRead = "Test Read from App Group"
        
        static let labelScore = "Score"
        static let labelBand = "Band"
        
        static let statusInitial = "Not tested yet"
        static let statusWriteSuccess = "✅ SUCCESS: Wrote test data to App Group"
        static let statusReadSuccess = "✅ SUCCESS: Read data from App Group"
        static let statusNoData = "⚠️ WARNING: App Group accessible but no data found"
        static let statusFailed = "❌ FAILED: Could not access App Group"
        static let messageNoData = "No data in App Group"
    }
}
