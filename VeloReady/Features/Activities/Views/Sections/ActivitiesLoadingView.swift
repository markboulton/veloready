import SwiftUI

/// Loading view with skeleton placeholders for activities list
struct ActivitiesLoadingView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(ActivitiesContent.loadingActivities)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                
                // Skeleton activity cards
                ForEach(0..<8, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        // Title skeleton
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 16)
                        
                        // Date/stats skeleton
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 80, height: 12)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 60, height: 12)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 70, height: 12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .shimmerActivityList()
                }
            }
        }
    }
}

// MARK: - Preview

struct ActivitiesLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitiesLoadingView()
    }
}
