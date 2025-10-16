import SwiftUI

/// Training zones section
struct TrainingZonesSection: View {
    @ObservedObject var proConfig: ProFeatureConfig
    
    var body: some View {
        Section {
            // PRO: Adaptive Zones (computed from performance data)
            if proConfig.hasProAccess {
                NavigationLink(destination: AthleteZonesSettingsView()) {
                    HStack {
                        Image(systemName: "bolt.heart.fill")
                            .foregroundColor(ColorScale.purpleAccent)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Adaptive Zones")
                                    .font(.body)
                                
                                Text("PRO")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ColorScale.purpleAccent)
                                    .cornerRadius(4)
                            }
                            
                            Text("Adaptive FTP, W', VO2max & Zones")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // FREE: HR and Power Zones (Coggan)
            if !proConfig.hasProAccess {
                NavigationLink(destination: AthleteZonesSettingsView()) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color.health.heartRate)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HR and Power Zones")
                                .font(.body)
                            
                            Text("Coggan zones based on FTP and Max HR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        } header: {
            Text("Training")
        } footer: {
            if proConfig.hasProAccess {
                Text("Adaptive Zones uses sports science to compute your FTP, W', and training zones from your performance data.")
            } else {
                Text("Set your FTP and Max HR to generate Coggan training zones. Upgrade to PRO for adaptive zones computed from your performance data.")
            }
        }
    }
}

// MARK: - Preview

struct TrainingZonesSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TrainingZonesSection(proConfig: ProFeatureConfig.shared)
        }
        .previewLayout(.sizeThatFits)
    }
}
