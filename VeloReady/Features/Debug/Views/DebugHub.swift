import SwiftUI

#if DEBUG
/// Main debug hub with tab-based navigation
struct DebugHub: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            TabView {
                DebugAuthView()
                    .tabItem {
                        Label("Auth", systemImage: Icons.System.shield)
                    }
                
                DebugCacheView()
                    .tabItem {
                        Label("Cache", systemImage: Icons.System.storage)
                    }
                
                DebugFeaturesView()
                    .tabItem {
                        Label("Features", systemImage: Icons.System.star)
                    }
                
                DebugNetworkView()
                    .tabItem {
                        Label("Network", systemImage: Icons.System.network)
                    }
                
                DebugHealthView()
                    .tabItem {
                        Label("Health", systemImage: Icons.Health.heartFill)
                    }
            }
            .navigationTitle(DebugContent.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DebugContent.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DebugHub()
}
#endif
