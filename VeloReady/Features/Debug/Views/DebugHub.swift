import SwiftUI

#if DEBUG
/// Main debug hub with standard iOS list-based navigation
struct DebugHub: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    DebugAuthView()
                } label: {
                    Label("Auth", systemImage: Icons.System.shield)
                }
                
                NavigationLink {
                    DebugCacheView()
                } label: {
                    Label("Cache", systemImage: Icons.System.storage)
                }
                
                NavigationLink {
                    DebugFeaturesView()
                } label: {
                    Label("Features", systemImage: Icons.System.star)
                }
                
                NavigationLink {
                    DebugNetworkView()
                } label: {
                    Label("Network", systemImage: Icons.System.network)
                }
                
                NavigationLink {
                    DebugHealthView()
                } label: {
                    Label("Health", systemImage: Icons.Health.heartFill)
                }
            } header: {
                Text("Debug Tools")
            } footer: {
                VRText(
                    "Development and testing utilities. DEBUG builds only.",
                    style: .caption,
                    color: .secondary
                )
            }
            
            Section {
                NavigationLink {
                    CardGalleryDebugView()
                } label: {
                    Label("Card Gallery", systemImage: Icons.System.grid2x2)
                }
                
                NavigationLink {
                    ColorPaletteDebugView()
                } label: {
                    Label("Color Palette", systemImage: Icons.System.sparkles)
                }
            } header: {
                Text("Design System")
            }
        }
        .navigationTitle(DebugContent.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    DebugHub()
}
#endif
