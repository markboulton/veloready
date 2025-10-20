import SwiftUI

/// Visual indicator for pull-to-refresh
struct PullToRefreshIndicator: View {
    let state: PullToRefreshState
    let progress: Double
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Progress circle (pulling state)
                if case .pulling = state {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.button.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? .linear(duration: 0.1) : .easeOut(duration: 0.15), value: progress)
                }
                
                // Filled circle (armed state)
                if case .armed = state {
                    Circle()
                        .fill(Color.button.primary)
                        .frame(width: 24, height: 24)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Spinner (refreshing state)
                if case .refreshing = state {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.button.primary))
                        .scaleEffect(1.0)
                }
                
                // Checkmark (completed state)
                if case .completed = state {
                    Image(systemName: Icons.Status.checkmark)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.semantic.success))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 32, height: 32)
            
            // Status text
            if let statusText = statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(Color.text.secondary)
                    .transition(.opacity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var statusText: String? {
        switch state {
        case .idle:
            return nil
        case .pulling:
            return progress < 0.9 ? "Pull to refresh" : "Release to refresh"
        case .armed:
            return "Release to refresh"
        case .refreshing:
            return "Refreshing…"
        case .completed:
            return "Updated"
        }
    }
    
    private var accessibilityLabel: String {
        switch state {
        case .idle:
            return ""
        case .pulling(let progress):
            return progress < 0.9 ? "Pull to refresh" : "Release to refresh"
        case .armed:
            return "Release to refresh"
        case .refreshing:
            return "Refreshing"
        case .completed:
            return "Refreshed"
        }
    }
}
