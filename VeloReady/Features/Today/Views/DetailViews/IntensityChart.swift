import SwiftUI
import Charts

/// Intensity chart showing IF and TSS with visual indicators and comparison
/// PRO Feature
struct IntensityChart: View {
    let activity: IntervalsActivity
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    
    var body: some View {
        guard proConfig.hasProAccess else {
            return AnyView(EmptyView())
        }
        
        guard let intensityFactorRaw = activity.intensityFactor,
              let tss = activity.tss else {
            return AnyView(EmptyView())
        }
        
        // Normalize IF to 0-1.0 range
        // Intervals.icu returns as percentage (78.64), Strava returns as decimal (0.81)
        let intensityFactor = intensityFactorRaw > 10.0 ? intensityFactorRaw / 100.0 : intensityFactorRaw
        
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Text("Ride Intensity")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                // Intensity Factor gauge with explanation
                VStack(alignment: .leading, spacing: 12) {
                    Text("Intensity Factor (IF)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(alignment: .top, spacing: 20) {
                        // Circular gauge
                        ZStack {
                            // Background circle
                            Circle()
                                .stroke(ColorScale.gray200, lineWidth: 12)
                                .frame(width: 100, height: 100)
                            
                            // Progress circle
                            Circle()
                                .trim(from: 0, to: min(intensityFactor, 1.0))
                                .stroke(intensityColor(intensityFactor), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                            
                            // Value and label
                            VStack(spacing: 2) {
                                Text(String(format: "%.2f", intensityFactor))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(intensityColor(intensityFactor))
                                Text("of 1.0")
                                    .font(.caption)
                                    .foregroundColor(Color.text.secondary)
                            }
                        }
                        
                        // Explanation and comparison
                        VStack(alignment: .leading, spacing: 8) {
                            Text(intensityLabel(intensityFactor))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(intensityColor(intensityFactor))
                            
                            Text("Weighted average power relative to FTP")
                                .font(.caption)
                                .foregroundColor(Color.text.secondary)
                            
                            Text("This ride had an IF of \(String(format: "%.2f", intensityFactor)), meaning varied efforts averaged to this intensity.")
                                .font(.caption)
                                .foregroundColor(Color.text.secondary)
                                .padding(.top, 2)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // TSS with explanation
                VStack(alignment: .leading, spacing: 8) {
                    
                    HStack {
                        Text("Training Stress Score (TSS)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(String(format: "%.0f", tss))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(tssColor(tss))
                    }
                    
                    Text("Total training load from this ride")
                        .font(.caption)
                        .foregroundColor(Color.text.secondary)
                    
                    // TSS category bar
                    HStack(spacing: 4) {
                        tssSegment(label: "Light", range: 0..<50, value: tss, color: Color.semantic.success)
                        tssSegment(label: "Moderate", range: 50..<90, value: tss, color: Color.button.primary)
                        tssSegment(label: "Hard", range: 90..<120, value: tss, color: Color.semantic.warning)
                        tssSegment(label: "Very Hard", range: 120..<200, value: tss, color: Color.semantic.error)
                    }
                    .frame(height: 24)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    
                    Text(tssDescription(tss))
                        .font(.caption)
                        .foregroundColor(Color.text.secondary)
                }
            }
        )
    }
    
    // MARK: - Helper Views
    
    private func comparisonRow(label: String, range: String, matches: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(matches ? Color.text.primary : Color.clear)
                .stroke(matches ? Color.clear : ColorScale.divider, lineWidth: 1)
                .frame(width: 6, height: 6)
            
            Text(label)
                .font(.caption)
                .foregroundColor(matches ? Color.text.primary : Color.text.secondary)
            
            Text(range)
                .font(.caption)
                .foregroundColor(Color.text.secondary)
        }
    }
    
    private func tssSegment(label: String, range: Range<Int>, value: Double, color: Color) -> some View {
        let isActive = range.contains(Int(value))
        let progress: Double = {
            if value < Double(range.lowerBound) {
                return 0
            } else if value >= Double(range.upperBound) {
                return 1.0
            } else {
                return (value - Double(range.lowerBound)) / Double(range.upperBound - range.lowerBound)
            }
        }()
        
        return VStack(spacing: 2) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(ColorScale.gray200)
                    .frame(height: 16)
                
                if isActive {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 16)
                    }
                } else if value >= Double(range.upperBound) {
                    Rectangle()
                        .fill(color)
                        .frame(height: 16)
                }
            }
            .cornerRadius(4)
            
            Text(label)
                .font(.caption)
                .foregroundColor(isActive ? color : Color.text.secondary)
        }
    }
    
    // MARK: - Helper Functions
    
    private func intensityColor(_ if: Double) -> Color {
        // 4-zone RAG color system for intensity
        if `if` < 0.75 {
            return ColorScale.greenAccent  // Recovery & Endurance - Green
        } else if `if` < 0.85 {
            return ColorScale.yellowAccent // Tempo - Yellow
        } else if `if` < 0.95 {
            return ColorScale.amberAccent  // Threshold - Amber/Orange
        } else {
            return ColorScale.redAccent    // VO2 Max+ - Red
        }
    }
    
    private func intensityLabel(_ if: Double) -> String {
        if `if` < 0.65 {
            return "Recovery-Focused"
        } else if `if` < 0.75 {
            return "Endurance-Focused"
        } else if `if` < 0.85 {
            return "Tempo-Focused"
        } else if `if` < 0.95 {
            return "Threshold-Focused"
        } else {
            return "High Intensity-Focused"
        }
    }
    
    private func tssColor(_ tss: Double) -> Color {
        if tss < 50 {
            return Color.semantic.success
        } else if tss < 90 {
            return Color.button.primary
        } else if tss < 120 {
            return Color.semantic.warning
        } else {
            return Color.semantic.error
        }
    }
    
    private func tssDescription(_ tss: Double) -> String {
        if tss < 50 {
            return "Light load - minimal fatigue, quick recovery"
        } else if tss < 90 {
            return "Moderate load - some fatigue, 1-2 days recovery"
        } else if tss < 120 {
            return "Hard load - significant fatigue, 2-3 days recovery"
        } else {
            return "Very hard load - heavy fatigue, 3+ days recovery"
        }
    }
}
