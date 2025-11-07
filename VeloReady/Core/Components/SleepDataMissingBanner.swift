import SwiftUI

/// Alert banner showing when sleep data is missing - styled with purple accent
struct SleepDataMissingBanner: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(ColorScale.purpleAccent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: Icons.Health.sleepFill)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(ColorScale.purpleAccent)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Sleep Data Missing")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("INFO")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ColorScale.purpleAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ColorScale.purpleAccent.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    Text("No sleep data detected from last night. Make sure your Apple Watch is worn during sleep and sleep tracking is enabled in the Health app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(ColorScale.purpleAccent.opacity(0.05))
            .overlay(
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(ColorScale.purpleAccent),
                alignment: .leading
            )
        }
    }
}

// MARK: - Preview

struct SleepDataMissingBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            SleepDataMissingBanner()
            Spacer()
        }
        .padding()
    }
}
