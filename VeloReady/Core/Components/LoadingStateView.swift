import SwiftUI

/// Reusable loading state component
/// Consistent loading indicators across the app
struct LoadingStateView: View {
    let message: String?
    let size: LoadingSize
    
    init(
        _ message: String? = nil,
        size: LoadingSize = .medium
    ) {
        self.message = message
        self.size = size
    }
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(size.scale)
                
                if let message = message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .trackComponent(.loadingStateView)
    }
}

enum LoadingSize {
    case small
    case medium
    case large
    
    var scale: CGFloat {
        switch self {
        case .small: return 0.7
        case .medium: return 1.0
        case .large: return 1.3
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingStateView("Loading data", size: .small)
        LoadingStateView("Processing", size: .medium)
        LoadingStateView(size: .large)
    }
    .padding()
}
