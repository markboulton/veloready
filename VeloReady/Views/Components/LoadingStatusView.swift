import SwiftUI

/// Apple Mail-style loading status indicator
struct LoadingStatusView: View {
    let state: LoadingState
    let onErrorTap: (() -> Void)?
    
    @State private var isVisible = false
    
    var body: some View {
        Group {
            if shouldShowStatus {
                HStack(spacing: Spacing.xs) {
                    if isLoadingState {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(Color.text.secondary)
                    }
                    
                    VRText(statusText, style: .bodySecondary)
                        .foregroundColor(statusColor)
                    
                    Spacer() // Push content to left
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Align left
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel)
                .onTapGesture {
                    if isErrorState {
                        onErrorTap?()
                    }
                }
                .transition(.opacity) // FIXED: Remove .move to prevent layout shift
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
        .onChange(of: state) { oldValue, newValue in
            handleStateChange(from: oldValue, to: newValue)
        }
    }
    
    private var accessibilityLabel: String {
        LoadingContent.accessibilityLabel(for: state)
    }
    
    private var statusText: String {
        switch state {
        case .initial:
            return ""
        case .fetchingHealthData:
            return LoadingContent.fetchingHealthData
        case .checkingForUpdates:
            return LoadingContent.checkingForUpdates
        case .calculatingScores(let hasHealthKit, let hasSleepData):
            return LoadingContent.calculatingScores(hasHealthKit: hasHealthKit, hasSleepData: hasSleepData)
        case .contactingIntegrations(let sources):
            return LoadingContent.contactingIntegrations(sources: sources)
        case .downloadingActivities(let count, let source):
            return LoadingContent.downloadingActivities(count: count, source: source)
        case .generatingInsights:
            return LoadingContent.generatingInsights
        case .computingZones:
            return LoadingContent.computingZones
        case .processingData:
            return LoadingContent.processingData
        case .savingToICloud:
            return LoadingContent.savingToICloud
        case .syncingData:
            return LoadingContent.syncingData
        case .refreshingScores:
            return LoadingContent.refreshingScores
        case .complete:
            return LoadingContent.complete
        case .updated(let date):
            return LoadingContent.updated(at: date)
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
        case .updated:
            return true  // Show updated status persistently
        default:
            return true
        }
    }
    
    private var isLoadingState: Bool {
        switch state {
        case .error, .complete, .updated:
            return false  // No spinner for these states
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
