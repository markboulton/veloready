import SwiftUI

/// Compact body stress indicator for navigation bar - matches WellnessIndicator design pattern
/// Shows illness indicator severity with RAG coloring in top-right of Today view
struct BodyStressIndicator: View {
    let indicator: IllnessIndicator
    let onTap: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: Icons.Status.warningFill)
                    .font(.caption)
                    .foregroundColor(severityColor)
                
                Text(CommonContent.WellnessAlerts.bodyStressDetected)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(severityColor)
                    .lineLimit(1)
                
                Image(systemName: Icons.System.chevronRight)
                    .font(.caption2)
                    .foregroundColor(severityColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .animation(.easeIn(duration: 0.3), value: isVisible)
        .onAppear {
            // Fade in quickly when appearing
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var severityColor: Color {
        switch indicator.severity {
        case .low:
            return ColorScale.yellowAccent
        case .moderate:
            return ColorScale.amberAccent
        case .high:
            return ColorScale.redAccent
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Low severity
        BodyStressIndicator(
            indicator: IllnessIndicator(
                date: Date(),
                severity: .low,
                confidence: 0.65,
                signals: [
                    IllnessIndicator.Signal(
                        type: .hrvDrop,
                        deviation: -12.0,
                        value: 45.0,
                        baseline: 51.1
                    )
                ],
                recommendation: "Monitor how you're feeling"
            ),
            onTap: {}
        )
        
        // Moderate severity
        BodyStressIndicator(
            indicator: IllnessIndicator(
                date: Date(),
                severity: .moderate,
                confidence: 0.78,
                signals: [
                    IllnessIndicator.Signal(
                        type: .elevatedRHR,
                        deviation: 8.5,
                        value: 62.0,
                        baseline: 57.1
                    ),
                    IllnessIndicator.Signal(
                        type: .hrvDrop,
                        deviation: -18.2,
                        value: 42.5,
                        baseline: 52.0
                    )
                ],
                recommendation: "Take it easy with training"
            ),
            onTap: {}
        )
        
        // High severity
        BodyStressIndicator(
            indicator: IllnessIndicator(
                date: Date(),
                severity: .high,
                confidence: 0.89,
                signals: [
                    IllnessIndicator.Signal(
                        type: .elevatedRHR,
                        deviation: 15.8,
                        value: 65.0,
                        baseline: 56.1
                    ),
                    IllnessIndicator.Signal(
                        type: .hrvDrop,
                        deviation: -28.4,
                        value: 38.5,
                        baseline: 53.8
                    ),
                    IllnessIndicator.Signal(
                        type: .respiratoryRate,
                        deviation: 14.2,
                        value: 18.5,
                        baseline: 16.2
                    )
                ],
                recommendation: "Rest is strongly recommended"
            ),
            onTap: {}
        )
    }
    .padding()
}
