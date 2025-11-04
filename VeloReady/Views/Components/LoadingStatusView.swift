import SwiftUI

/// Apple Mail-style loading status indicator
struct LoadingStatusView: View {
    let state: LoadingState
    let onErrorTap: (() -> Void)?
    
    @State private var isVisible = false
    
    var body: some View {
        Group {
            if shouldShowStatus {
                statusContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
        .onChange(of: state) { oldValue, newValue in
            handleStateChange(from: oldValue, to: newValue)
        }
    }
    
    @ViewBuilder
    private var statusContent: some View {
        HStack(spacing: Spacing.xs) {
            // Loading spinner for active states
            if isLoadingState {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.text.secondary)
            }
            
            // Status text
            VRText(
                statusText,
                style: .caption,
                color: statusColor
            )
            .accessibilityLabel(LoadingContent.accessibilityLabel(for: state))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .if(isErrorState) { view in
            view.onTapGesture {
                onErrorTap?()
            }
        }
    }
    
    private var statusText: String {
        switch state {
        case .initial:
            return ""
        case .calculatingScores:
            return LoadingContent.calculatingScores
        case .contactingStrava:
            return LoadingContent.contactingStrava
        case .downloadingActivities(let count):
            return LoadingContent.downloadingActivities(count: count)
        case .processingData:
            return LoadingContent.processingData
        case .refreshingScores:
            return LoadingContent.refreshingScores
        case .complete:
            return LoadingContent.complete
        case .error(let error):
            switch error {
            case .network:
                return LoadingContent.networkError
            case .stravaAuth:
                return LoadingContent.stravaAuthError
            case .stravaAPI:
                return LoadingContent.stravaAPIError
            case .unknown(let message):
                return LoadingContent.unknownError(message)
            }
        }
    }
    
    private var statusColor: Color {
        if isErrorState {
            return Color.text.error
        }
        return Color.text.secondary
    }
    
    private var shouldShowStatus: Bool {
        switch state {
        case .initial, .complete:
            return false  // Don't show for these states
        default:
            return true
        }
    }
    
    private var isLoadingState: Bool {
        switch state {
        case .error:
            return false
        case .complete:
            return false
        default:
            return true
        }
    }
    
    private var isErrorState: Bool {
        if case .error = state {
            return true
        }
        return false
    }
    
    private func handleStateChange(from oldState: LoadingState, to newState: LoadingState) {
        // Handle state transitions
        if case .complete = newState {
            // Fade out after brief display
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isVisible = false
            }
        } else {
            isVisible = true
        }
    }
}

// MARK: - View Extension for Conditional Modification

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
