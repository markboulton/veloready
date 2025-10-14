# Custom Icons Integration Guide

## Overview
The icon system supports both SF Symbols and custom icons from your asset catalog.

## Adding Custom Icons

### Step 1: Add Icons to Asset Catalog

1. Open `VeloReady/Assets.xcassets`
2. Right-click → New Image Set
3. Name it (e.g., `custom-cycling-icon`)
4. Add your icon files:
   - **SVG**: Best for scalability (preserves vector)
   - **PDF**: Also scalable
   - **PNG**: Add @1x, @2x, @3x for different scales

### Step 2: Register in Icons.swift

```swift
enum Icons {
    enum Custom {
        static let brandedLogo = IconType.custom("veloready-logo")
        static let customCycling = IconType.custom("custom-cycling-icon")
    }
}
```

### Step 3: Use in Views

#### Option A: Using IconType (Recommended for new code)

```swift
// Custom icon
Icons.Custom.brandedLogo.image
    .resizable()
    .frame(width: 24, height: 24)
    .foregroundColor(.blue)

// SF Symbol (if using IconType)
IconType.system(Icons.Health.heart).image
    .font(.title)
```

#### Option B: Using String (Current pattern)

```swift
// SF Symbol
Image(systemName: Icons.Health.heart)
    .font(.title)

// Custom icon - need to detect type
if iconName.hasPrefix("custom-") {
    Image(iconName)  // Asset catalog
} else {
    Image(systemName: iconName)  // SF Symbol
}
```

## Migration Strategy

### Current State (Backwards Compatible)
All existing icons are strings pointing to SF Symbols:
```swift
enum Activity {
    static let cycling = "bicycle"  // SF Symbol
}

// Used as:
Image(systemName: Icons.Activity.cycling)
```

### Future State (Mixed Icons)
Can have both types:
```swift
enum Activity {
    static let cycling = "bicycle"  // SF Symbol
    static let cyclingBranded = IconType.custom("custom-cycling")  // Custom
}

// Used as:
Image(systemName: Icons.Activity.cycling)  // SF Symbol
Icons.Activity.cyclingBranded.image  // Custom
```

## Best Practices

### 1. Naming Convention
- **SF Symbols**: Use descriptive names matching Apple's convention
- **Custom icons**: Prefix with `custom-` or brand name
  - ✅ `custom-cycling-icon`
  - ✅ `veloready-logo`
  - ❌ `cycling` (conflicts with SF Symbol)

### 2. Icon Specifications
- **Format**: SVG or PDF for vector scalability
- **Size**: Design at 24×24pt (1x scale)
- **Color**: Single color (use foregroundColor in SwiftUI)
- **Style**: Match outlined SF Symbols aesthetic

### 3. Asset Catalog Settings
- **Render As**: Template Image (for color control)
- **Preserve Vector Data**: ✅ Enabled
- **Single Scale**: ✅ If using SVG/PDF

### 4. Accessibility
```swift
Icons.Custom.brandedLogo.image
    .resizable()
    .frame(width: 24, height: 24)
    .accessibilityLabel("VeloReady logo")
```

## Example: Replace Activity Icon with Custom

### Before (SF Symbol)
```swift
enum Activity {
    static let cycling = "bicycle"
}

// In view:
Image(systemName: Icons.Activity.cycling)
```

### After (Custom Icon)
```swift
enum Activity {
    static let cycling = "bicycle"  // Keep for backwards compatibility
    static let cyclingBranded = IconType.custom("custom-cycling-icon")
}

// In view - choose which to use:
Icons.Activity.cyclingBranded.image
    .resizable()
    .frame(width: 24, height: 24)
    .foregroundColor(.blue)
```

## Advanced: Dynamic Icon Selection

```swift
struct ActivityIcon: View {
    let activity: ActivityType
    let useCustomIcons: Bool
    
    var body: some View {
        if useCustomIcons, let customIcon = customIconForActivity(activity) {
            customIcon.image
                .resizable()
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: activity.icon)
                .font(.title3)
        }
    }
    
    private func customIconForActivity(_ activity: ActivityType) -> IconType? {
        switch activity {
        case .cycling: return Icons.Custom.cyclingBranded
        case .strength: return Icons.Custom.strengthBranded
        default: return nil
        }
    }
}
```

## Migration Checklist

- [ ] Add custom icons to Assets.xcassets
- [ ] Register in Icons.Custom enum
- [ ] Update views to use custom icons where desired
- [ ] Test at different scale factors (@1x, @2x, @3x)
- [ ] Verify dark mode appearance
- [ ] Add accessibility labels
- [ ] Document brand guidelines

## Troubleshooting

**Icon not showing:**
- ✅ Check asset name matches exactly (case-sensitive)
- ✅ Verify "Render As: Template Image" is set
- ✅ Check icon is in correct target membership

**Icon wrong color:**
- ✅ Use `.foregroundColor()` modifier
- ✅ Check "Render As: Template Image"

**Icon blurry:**
- ✅ Use SVG or PDF with "Preserve Vector Data"
- ✅ Use `.resizable()` with explicit frame
