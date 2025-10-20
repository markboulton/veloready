import SwiftUI

/// About section showing app info
struct AboutSection: View {
    var body: some View {
        Section {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(ColorPalette.labelSecondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text(SettingsContent.About.title)
                        .font(TypeScale.font(size: TypeScale.md))
                    
                    Text(SettingsContent.About.version)
                        .font(TypeScale.font(size: TypeScale.xs))
                        .foregroundColor(ColorPalette.labelSecondary)
                }
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(ColorPalette.labelSecondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text(SettingsContent.About.helpTitle)
                        .font(TypeScale.font(size: TypeScale.md))
                    
                    Text(SettingsContent.About.helpDescription)
                        .font(TypeScale.font(size: TypeScale.xs))
                        .foregroundColor(ColorPalette.labelSecondary)
                }
                
                Spacer()
            }
        } header: {
            Text(SettingsContent.aboutSection)
        }
    }
}

// MARK: - Preview

struct AboutSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AboutSection()
        }
        .previewLayout(.sizeThatFits)
    }
}
