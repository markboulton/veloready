import SwiftUI

/// Debug view displaying the complete color palette with swatches, values, and names
/// Helps visually choose colors for the app
struct ColorPaletteDebugView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // MARK: - Status Colors
                    
                    sectionHeader("Status Colors", subtitle: "Success, Warning, Error")
                    
                    HStack(spacing: Spacing.md) {
                        colorSwatch(
                            name: "Success",
                            color: ColorPalette.success,
                            isAdaptive: true
                        )
                        colorSwatch(
                            name: "Warning",
                            color: ColorPalette.warning,
                            isAdaptive: true
                        )
                        colorSwatch(
                            name: "Error",
                            color: ColorPalette.error,
                            isAdaptive: true
                        )
                    }
                    
                    // MARK: - Accent Colors
                    
                    sectionHeader("Accent Colors", subtitle: "Team & Route Colors")
                    
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.md) {
                            colorSwatch(name: "Mint", color: ColorPalette.mint, isAdaptive: false)
                            colorSwatch(name: "Peach", color: ColorPalette.peach, isAdaptive: false)
                            colorSwatch(name: "Blue", color: ColorPalette.blue, isAdaptive: false)
                        }
                        HStack(spacing: Spacing.md) {
                            colorSwatch(name: "Purple", color: ColorPalette.purple, isAdaptive: false)
                            colorSwatch(name: "Pink", color: ColorPalette.pink, isAdaptive: false)
                            colorSwatch(name: "Cyan", color: ColorPalette.cyan, isAdaptive: false)
                        }
                        HStack(spacing: Spacing.md) {
                            colorSwatch(name: "Yellow", color: ColorPalette.yellow, isAdaptive: false)
                            Spacer()
                            Spacer()
                        }
                    }
                    
                    // MARK: - Neutral Colors
                    
                    sectionHeader("Neutral Colors", subtitle: "Grayscale palette")
                    
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.md) {
                            colorSwatch(name: "100", color: ColorPalette.neutral100, isAdaptive: true)
                            colorSwatch(name: "200", color: ColorPalette.neutral200, isAdaptive: true)
                            colorSwatch(name: "300", color: ColorPalette.neutral300, isAdaptive: true)
                        }
                        HStack(spacing: Spacing.md) {
                            colorSwatch(name: "400", color: ColorPalette.neutral400, isAdaptive: true)
                            colorSwatch(name: "500", color: ColorPalette.neutral500, isAdaptive: true)
                            colorSwatch(name: "600", color: ColorPalette.neutral600, isAdaptive: true)
                        }
                        HStack(spacing: Spacing.md) {
                            colorSwatch(name: "900", color: ColorPalette.neutral900, isAdaptive: true)
                            Spacer()
                            Spacer()
                        }
                    }
                    
                    // MARK: - Background Colors
                    
                    sectionHeader("Background Colors", subtitle: "Adaptive backgrounds")
                    
                    VStack(spacing: Spacing.sm) {
                        colorSwatchFull(
                            name: "Primary",
                            color: ColorPalette.backgroundPrimary,
                            isAdaptive: true,
                            description: "White in light mode, Black in dark mode"
                        )
                        colorSwatchFull(
                            name: "Secondary",
                            color: ColorPalette.backgroundSecondary,
                            isAdaptive: true,
                            description: "Light grey in light mode, Dark grey in dark mode"
                        )
                        colorSwatchFull(
                            name: "Tertiary",
                            color: ColorPalette.backgroundTertiary,
                            isAdaptive: true,
                            description: "White in light mode, Elevated dark grey in dark mode"
                        )
                        colorSwatchFull(
                            name: "List Item",
                            color: ColorPalette.backgroundListItem,
                            isAdaptive: true,
                            description: "White in light mode, Grey in dark mode (Settings style)"
                        )
                        colorSwatchFull(
                            name: "App Background",
                            color: ColorPalette.appBackground,
                            isAdaptive: true,
                            description: "Light grey in light mode, Black in dark mode"
                        )
                    }
                    
                    // MARK: - Label Colors
                    
                    sectionHeader("Label Colors", subtitle: "Text colors")
                    
                    HStack(spacing: Spacing.md) {
                        colorSwatch(name: "Primary", color: ColorPalette.labelPrimary, isAdaptive: true)
                        colorSwatch(name: "Secondary", color: ColorPalette.labelSecondary, isAdaptive: true)
                        colorSwatch(name: "Tertiary", color: ColorPalette.labelTertiary, isAdaptive: true)
                    }
                    
                    // MARK: - Metric Colors
                    
                    sectionHeader("Metric Colors", subtitle: "Health data visualization")
                    
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.md) {
                            colorSwatch(name: "Sleep", color: ColorPalette.sleepMetric, isAdaptive: true)
                            colorSwatch(name: "HRV", color: ColorPalette.hrvMetric, isAdaptive: true)
                            colorSwatch(name: "HR", color: ColorPalette.heartRateMetric, isAdaptive: true)
                        }
                        HStack(spacing: Spacing.md) {
                            colorSwatch(name: "Respiratory", color: ColorPalette.respiratoryMetric, isAdaptive: true)
                            colorSwatch(name: "Power", color: ColorPalette.powerMetric, isAdaptive: true)
                            colorSwatch(name: "TSS", color: ColorPalette.tssMetric, isAdaptive: true)
                        }
                        HStack(spacing: Spacing.md) {
                            colorSwatch(name: "Strain", color: ColorPalette.strainMetric, isAdaptive: true)
                            Spacer()
                            Spacer()
                        }
                    }
                    
                    // MARK: - Recovery Scale
                    
                    sectionHeader("Recovery Scale", subtitle: "Score-based gradient")
                    
                    VStack(spacing: Spacing.sm) {
                        colorSwatchFull(
                            name: "Poor",
                            color: ColorPalette.recoveryPoor,
                            isAdaptive: true,
                            description: "Recovery < 30"
                        )
                        colorSwatchFull(
                            name: "Low",
                            color: ColorPalette.recoveryLow,
                            isAdaptive: true,
                            description: "Recovery 30-50"
                        )
                        colorSwatchFull(
                            name: "Medium",
                            color: ColorPalette.recoveryMedium,
                            isAdaptive: true,
                            description: "Recovery 50-70"
                        )
                        colorSwatchFull(
                            name: "Good",
                            color: ColorPalette.recoveryGood,
                            isAdaptive: true,
                            description: "Recovery 70-85"
                        )
                        colorSwatchFull(
                            name: "Excellent",
                            color: ColorPalette.recoveryExcellent,
                            isAdaptive: true,
                            description: "Recovery 85+"
                        )
                    }
                    
                    // MARK: - AI Gradient Colors
                    
                    sectionHeader("AI Feature Colors", subtitle: "Gradient palette")
                    
                    VStack(spacing: Spacing.md) {
                        HStack(spacing: Spacing.md) {
                            ForEach(ColorPalette.aiGradientColors.indices, id: \.self) { index in
                                VStack(spacing: Spacing.xs) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(ColorPalette.aiGradientColors[index])
                                        .frame(height: 60)
                                    
                                    Text("Gradient \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.text.secondary)
                                }
                            }
                        }
                        
                        HStack(spacing: Spacing.md) {
                            VStack(spacing: Spacing.xs) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: ColorPalette.aiGradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 60)
                                
                                Text("Full Gradient")
                                    .font(.caption)
                                    .foregroundColor(.text.secondary)
                            }
                            Spacer()
                        }
                    }
                    
                    Spacer()
                        .frame(height: Spacing.lg)
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Color Palette")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.headline)
                .foregroundColor(.text.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.text.secondary)
        }
        .padding(.top, Spacing.md)
    }
    
    private func colorSwatch(
        name: String,
        color: Color,
        isAdaptive: Bool
    ) -> some View {
        VStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.text.tertiary.opacity(0.2), lineWidth: 1)
                )
            
            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.text.primary)
            
            if isAdaptive {
                Text("Adaptive")
                    .font(.caption2)
                    .foregroundColor(.text.tertiary)
            }
        }
    }
    
    private func colorSwatchFull(
        name: String,
        color: Color,
        isAdaptive: Bool,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.text.tertiary.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.text.primary)
                        
                        if isAdaptive {
                            Text("Adaptive")
                                .font(.caption2)
                                .foregroundColor(.text.tertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.background.secondary)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.text.secondary)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ColorPaletteDebugView()
}
