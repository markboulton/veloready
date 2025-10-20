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
                        Image(systemName: Icons.Health.boltHeart)
                            .foregroundColor(ColorScale.purpleAccent)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                            Text(SettingsContent.TrainingZones.adaptiveZonesTitle)
                                .font(TypeScale.font(size: TypeScale.md))
                            
                            Text(SettingsContent.TrainingZones.adaptiveZonesSubtitle)
                                .font(TypeScale.font(size: TypeScale.xs))
                                .foregroundColor(ColorPalette.labelSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // FREE: HR and Power Zones (Coggan)
            if !proConfig.hasProAccess {
                NavigationLink(destination: AthleteZonesSettingsView()) {
                    HStack {
                        Image(systemName: Icons.Health.heartFill)
                            .foregroundColor(Color.health.heartRate)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                            Text(SettingsContent.TrainingZones.title)
                                .font(TypeScale.font(size: TypeScale.md))
                            
                            Text(SettingsContent.TrainingZones.standardZonesSubtitle)
                                .font(TypeScale.font(size: TypeScale.xs))
                                .foregroundColor(ColorPalette.labelSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        } header: {
            Text(SettingsContent.trainingSection)
        } footer: {
            if proConfig.hasProAccess {
                Text(SettingsContent.TrainingZones.adaptiveZonesFooter)
            } else {
                Text(SettingsContent.TrainingZones.standardZonesFooter)
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
