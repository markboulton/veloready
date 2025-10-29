# Liquid Glass Design System Guide

## Overview

VeloReady now features a modern **Liquid Glass** design language that combines:
- **Translucent materials** with depth and blur
- **Fluid animations** using spring physics
- **Layered elevation** for visual hierarchy
- **Interactive states** with responsive feedback
- **Adaptive colors** optimized for glass surfaces

## Core Components

### 1. Glass Materials

Four material types for different use cases:

```swift
.glassBackground(material: .ultraThin)  // Maximum transparency
.glassBackground(material: .thin)        // Light blur
.glassBackground(material: .regular)     // Standard glass (default)
.glassBackground(material: .thick)       // Heavy blur, prominent
```

### 2. Glass Cards

The primary building block - cards with automatic glass styling:

```swift
// Automatically uses glass materials
Card(style: .elevated) {
    Text("Content")
}

// Or apply directly to any view
VStack {
    Text("Content")
}
.glassCard(material: .regular, elevation: .medium)
```

**Card Styles:**
- `.elevated` - Regular glass, medium shadow (standard cards)
- `.flat` - Thin glass, low shadow (subtle cards)
- `.outlined` - Ultra-thin glass, no shadow (transparent overlays)

### 3. Elevation System

```swift
.glassCard(material: .regular, elevation: .flat)      // No shadow
.glassCard(material: .regular, elevation: .low)       // 2px elevation
.glassCard(material: .regular, elevation: .medium)    // 4px elevation (standard)
.glassCard(material: .regular, elevation: .high)      // 8px elevation
.glassCard(material: .regular, elevation: .floating)  // 12px elevation (FAB, modals)
```

## Buttons

### Primary Actions

```swift
Button("Save") { }
    .primaryGlassButton()
```
- Gradient fill with glass overlay
- Prominent shadow and glow
- Smooth press animation

### Secondary Actions

```swift
Button("Cancel") { }
    .secondaryGlassButton()
```
- Glass background
- Colored text
- Subtle interaction

### Icon Buttons

```swift
Button {
} label: {
    Image(systemName: "heart.fill")
}
.iconGlassButton(size: 44, tintColor: .red)
```

### Floating Action Button

```swift
Button {
} label: {
    Image(systemName: "plus")
}
.floatingActionButton(color: .blue)
```

### Compact & Pills

```swift
Button("Tag") { }
    .compactGlassButton(tintColor: .blue)

Button("Filter") { }
    .pillGlassButton(color: .purple)
```

## Animations

Use fluid spring animations for smooth, natural motion:

```swift
// Quick snap for immediate feedback
.snapAnimation(value: isPressed)

// Smooth flow for transitions
.fluidAnimation(value: selectedTab)

// Bouncy for playful interactions
.animation(FluidAnimation.bouncy, value: showContent)

// Gentle for subtle movements
.animation(FluidAnimation.gentle, value: scrollOffset)
```

**Animation Types:**
- `FluidAnimation.snap` - Quick UI feedback (0.3s, 0.7 damping)
- `FluidAnimation.flow` - Smooth transitions (0.5s, 0.8 damping)
- `FluidAnimation.gentle` - Subtle movements (0.6s, 0.9 damping)
- `FluidAnimation.bouncy` - Playful interactions (0.4s, 0.6 damping)
- `FluidAnimation.ease` - Linear movements (0.3s ease-in-out)
- `FluidAnimation.quick` - State changes (0.2s ease-out)

## Effects

### Shimmer

Add animated shimmer for loading or highlighting:

```swift
Text("Loading...")
    .shimmer(speed: 2.0)
```

### Glow

Add multi-layer glow for emphasis:

```swift
Circle()
    .fill(Color.blue)
    .glow(color: .blue, intensity: 1.0)
```

### Depth Layers

Add subtle parallax depth:

```swift
Image("hero")
    .depthLayer(0.05)  // Slight parallax
```

## Sheets & Modals

### Bottom Sheets

```swift
GlassBottomSheet(isPresented: $showSheet, height: 400) {
    VStack {
        Text("Sheet Content")
    }
}
```

### Floating Panels

```swift
FloatingPanel(width: 300) {
    VStack {
        Text("Panel Content")
    }
}
```

### Glass Alerts

```swift
GlassAlert(
    title: "Alert Title",
    message: "Alert message",
    icon: "checkmark.circle.fill",
    iconColor: .green
) {
    HStack {
        Button("Cancel") { }
            .secondaryGlassButton()
        Button("OK") { }
            .primaryGlassButton()
    }
}
```

### Toast Notifications

```swift
@State private var showToast = false

GlassToast(
    message: "Action completed",
    icon: "checkmark.circle.fill",
    iconColor: .green,
    isShowing: $showToast
)
```

## Navigation

### Glass Navigation Bar

```swift
NavigationView {
    ContentView()
}
.glassNavigationBar()
```

### Glass Tab Bar

```swift
TabView {
    // tabs
}
.glassTabBar()
```

## Interactive States

### Pressable Cards

```swift
VStack {
    Text("Tap me")
}
.pressableGlass {
    print("Tapped!")
}
```

## Colors for Glass

Use optimized colors that work well with translucent materials:

```swift
// Accent colors
GlassColors.primaryAccent    // Blue with opacity
GlassColors.successAccent    // Green with opacity
GlassColors.warningAccent    // Orange with opacity
GlassColors.errorAccent      // Red with opacity

// Tints for glass surfaces
GlassColors.glassTintLight   // White tint
GlassColors.glassTintDark    // Black tint
GlassColors.glassTintPurple  // Purple tint
GlassColors.glassTintBlue    // Blue tint
```

## Migration Guide

### Before (Old Style)

```swift
VStack {
    Text("Content")
}
.background(Color.background.secondary)
.cornerRadius(12)
.shadow(radius: 4)
```

### After (Liquid Glass)

```swift
VStack {
    Text("Content")
}
.glassCard(material: .regular, elevation: .medium)
```

### Button Migration

**Before:**
```swift
Button("Action") { }
    .buttonStyle(.borderedProminent)
```

**After:**
```swift
Button("Action") { }
    .primaryGlassButton()
```

## Best Practices

### 1. **Layer Hierarchy**
- Use `.ultraThin` for overlays on top of content
- Use `.thin` for secondary cards
- Use `.regular` for primary cards
- Use `.thick` for modals and alerts

### 2. **Elevation Guidelines**
- `.flat` - Inline elements, no separation needed
- `.low` - Subtle cards within sections
- `.medium` - Standard cards (most common)
- `.high` - Important cards, headers
- `.floating` - FABs, modal sheets, popovers

### 3. **Animation Selection**
- Use `.snap` for button presses and toggles
- Use `.flow` for view transitions and navigation
- Use `.gentle` for background movements
- Use `.bouncy` for playful, attention-grabbing interactions

### 4. **Performance**
- Glass materials use system blur - performant but use sparingly in lists
- Avoid stacking too many glass layers (max 2-3 depth)
- Use `.ultraThin` in scroll views for better performance

### 5. **Accessibility**
- Glass materials adapt to reduce transparency when "Reduce Transparency" is enabled
- Always ensure sufficient color contrast
- Test in both light and dark modes

## Examples

### Dashboard Card

```swift
Card(style: .elevated) {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Text("Recovery Score")
                .font(.headline)
            Spacer()
            Text("85%")
                .font(.title)
                .fontWeight(.bold)
        }
        
        Text("Optimal for training")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
}
.snapAnimation(value: recoveryScore)
```

### Interactive Button Row

```swift
HStack(spacing: 12) {
    Button {
        // action
    } label: {
        Image(systemName: "heart.fill")
    }
    .iconGlassButton(size: 44, tintColor: .red)
    .glow(color: .red, intensity: 0.5)
    
    Button("View Details") {
        // action
    }
    .primaryGlassButton()
}
```

### Modal Sheet

```swift
.sheet(isPresented: $showSettings) {
    NavigationView {
        SettingsView()
    }
    .glassSheet()
}
```

## Design Tokens

All design tokens are centralized in `LiquidGlass.swift`:

- **Materials**: `GlassMaterial` enum
- **Elevation**: `GlassElevation` enum  
- **Animations**: `FluidAnimation` enum
- **Colors**: `GlassColors` struct

## Platform Support

- **iOS 18+**: Full support for all glass materials
- **iOS 17**: Falls back to similar system materials
- **iOS 16**: Uses `.ultraThinMaterial` as fallback

---

**Questions or Issues?**
Refer to `LiquidGlass.swift`, `LiquidGlassButtons.swift`, and `LiquidGlassSheets.swift` for implementation details.
