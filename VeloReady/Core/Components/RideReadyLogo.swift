import SwiftUI

/// RideReady logo component - text-based for now
struct RideReadyLogo: View {
    let size: LogoSize
    
    enum LogoSize {
        case small, medium, large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 36
            case .large: return 48
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 8
            case .large: return 12
            }
        }
    }
    
    var body: some View {
        VStack(spacing: size.spacing) {
            // Logo icon (bicycle in circle for now)
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: size.fontSize * 2, height: size.fontSize * 2)
                
                Image(systemName: "bicycle")
                    .font(.system(size: size.fontSize))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Text logo
            Text("RideReady")
                .font(.system(size: size.fontSize, weight: .bold, design: .default))
                .tracking(1)
                .foregroundStyle(LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
        }
    }
}

// MARK: - Preview

struct RideReadyLogo_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            RideReadyLogo(size: .small)
            RideReadyLogo(size: .medium)
            RideReadyLogo(size: .large)
        }
        .padding()
    }
}
