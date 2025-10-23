# Phase 5 Implementation Guide: Design System Completion

**Goal:** Zero hard-coded values, 100% design token usage  
**Timeline:** Week 9 (1 week)  
**Status:** Ready to implement  
**Prerequisites:** Phase 1, 2, 3, 4 complete

---

## Executive Summary

VeloReady has a **strong design foundation** with `DesignTokens.swift` and color/spacing systems. However, some components still bypass the design system with hard-coded values. This final phase eliminates all hard-coded styling and creates a production-ready design system.

### Current Issues
- ⚠️ **Some hard-coded colors** - A few components use `.blue`, `.red` directly
- ⚠️ **Some hard-coded spacing** - Padding values like `12`, `16` inline
- ⚠️ **No typography system** - Font sizes scattered across files
- ⚠️ **No shadow system** - Shadow values duplicated
- ⚠️ **No animation system** - Animation durations hard-coded

### Phase 5 Goals
✅ **Zero hard-coded values** in production code  
✅ **Complete design tokens** - Colors, spacing, typography, shadows, animations  
✅ **Design documentation** - Usage guidelines  
✅ **Figma sync** - Design tokens match Figma  
✅ **Dark mode perfection** - All tokens adaptive  

---

## Step 1: Typography System

### File: `Design/DesignTokens+Typography.swift`
```swift
import SwiftUI

extension DesignTokens {
    /// Typography system - all text styles
    enum Typography {
        // MARK: - Display Styles
        case displayLarge      // 57pt, Bold
        case displayMedium     // 45pt, Bold
        case displaySmall      // 36pt, Bold
        
        // MARK: - Headline Styles
        case headlineLarge     // 32pt, Bold
        case headlineMedium    // 28pt, Semibold
        case headlineSmall     // 24pt, Semibold
        
        // MARK: - Title Styles
        case titleLarge        // 22pt, Semibold
        case titleMedium       // 16pt, Medium
        case titleSmall        // 14pt, Medium
        
        // MARK: - Body Styles
        case bodyLarge         // 16pt, Regular
        case bodyMedium        // 14pt, Regular
        case bodySmall         // 12pt, Regular
        
        // MARK: - Label Styles
        case labelLarge        // 14pt, Medium
        case labelMedium       // 12pt, Medium
        case labelSmall        // 11pt, Medium
        
        var font: Font {
            switch self {
            // Display
            case .displayLarge: return .system(size: 57, weight: .bold, design: .rounded)
            case .displayMedium: return .system(size: 45, weight: .bold, design: .rounded)
            case .displaySmall: return .system(size: 36, weight: .bold, design: .rounded)
            
            // Headlines
            case .headlineLarge: return .system(size: 32, weight: .bold)
            case .headlineMedium: return .system(size: 28, weight: .semibold)
            case .headlineSmall: return .system(size: 24, weight: .semibold)
            
            // Titles
            case .titleLarge: return .system(size: 22, weight: .semibold)
            case .titleMedium: return .system(size: 16, weight: .medium)
            case .titleSmall: return .system(size: 14, weight: .medium)
            
            // Body
            case .bodyLarge: return .system(size: 16, weight: .regular)
            case .bodyMedium: return .system(size: 14, weight: .regular)
            case .bodySmall: return .system(size: 12, weight: .regular)
            
            // Labels
            case .labelLarge: return .system(size: 14, weight: .medium)
            case .labelMedium: return .system(size: 12, weight: .medium)
            case .labelSmall: return .system(size: 11, weight: .medium)
            }
        }
        
        var lineHeight: CGFloat {
            switch self {
            case .displayLarge: return 64
            case .displayMedium: return 52
            case .displaySmall: return 44
            case .headlineLarge: return 40
            case .headlineMedium: return 36
            case .headlineSmall: return 32
            case .titleLarge: return 28
            case .titleMedium: return 24
            case .titleSmall: return 20
            case .bodyLarge: return 24
            case .bodyMedium: return 20
            case .bodySmall: return 16
            case .labelLarge: return 20
            case .labelMedium: return 16
            case .labelSmall: return 16
            }
        }
        
        var letterSpacing: CGFloat {
            switch self {
            case .displayLarge, .displayMedium, .displaySmall: return -0.5
            case .headlineLarge, .headlineMedium: return -0.5
            case .headlineSmall: return 0
            case .titleLarge, .titleMedium, .titleSmall: return 0.15
            case .bodyLarge, .bodyMedium, .bodySmall: return 0.5
            case .labelLarge, .labelMedium, .labelSmall: return 0.5
            }
        }
    }
}

// MARK: - SwiftUI Extension
extension Text {
    func typography(_ style: DesignTokens.Typography) -> Text {
        self
            .font(style.font)
            .tracking(style.letterSpacing)
            .lineSpacing(style.lineHeight - style.font.pointSize)
    }
}

// MARK: - Usage
struct ExampleView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Display Large").typography(.displayLarge)
            Text("Headline Medium").typography(.headlineMedium)
            Text("Body text example").typography(.bodyMedium)
            Text("Small label").typography(.labelSmall)
        }
    }
}
```

---

## Step 2: Shadow System

### File: `Design/DesignTokens+Shadows.swift`
```swift
import SwiftUI

extension DesignTokens {
    /// Shadow system - elevation levels
    enum Shadow {
        case none
        case small       // Subtle depth
        case medium      // Card elevation
        case large       // Modal/sheet
        case extraLarge  // Floating button
        
        var color: Color {
            Color.black.opacity(opacity)
        }
        
        var opacity: Double {
            switch self {
            case .none: return 0
            case .small: return 0.05
            case .medium: return 0.1
            case .large: return 0.15
            case .extraLarge: return 0.2
            }
        }
        
        var radius: CGFloat {
            switch self {
            case .none: return 0
            case .small: return 4
            case .medium: return 8
            case .large: return 16
            case .extraLarge: return 24
            }
        }
        
        var offset: CGSize {
            switch self {
            case .none: return .zero
            case .small: return CGSize(width: 0, height: 1)
            case .medium: return CGSize(width: 0, height: 2)
            case .large: return CGSize(width: 0, height: 4)
            case .extraLarge: return CGSize(width: 0, height: 8)
            }
        }
    }
}

// MARK: - SwiftUI Extension
extension View {
    func elevation(_ level: DesignTokens.Shadow) -> some View {
        self.shadow(
            color: level.color,
            radius: level.radius,
            x: level.offset.width,
            y: level.offset.height
        )
    }
}

// MARK: - Usage
struct CardView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .frame(height: 200)
            .elevation(.medium)  // ← Design token
    }
}
```

---

## Step 3: Animation System

### File: `Design/DesignTokens+Animations.swift`
```swift
import SwiftUI

extension DesignTokens {
    /// Animation system - consistent timing
    enum AnimationTiming {
        case instant      // 0s - No animation
        case fast         // 0.15s - Quick feedback
        case normal       // 0.3s - Standard
        case slow         // 0.5s - Deliberate
        case verySlow     // 0.8s - Dramatic
        
        var duration: Double {
            switch self {
            case .instant: return 0
            case .fast: return 0.15
            case .normal: return 0.3
            case .slow: return 0.5
            case .verySlow: return 0.8
            }
        }
        
        var animation: Animation {
            switch self {
            case .instant: return .none
            case .fast: return .easeInOut(duration: 0.15)
            case .normal: return .spring(response: 0.3, dampingFraction: 0.8)
            case .slow: return .spring(response: 0.5, dampingFraction: 0.75)
            case .verySlow: return .spring(response: 0.8, dampingFraction: 0.7)
            }
        }
    }
    
    /// Animation curves
    enum AnimationCurve {
        case linear
        case easeIn
        case easeOut
        case easeInOut
        case spring(response: Double, dampingFraction: Double)
        
        func animation(duration: Double) -> Animation {
            switch self {
            case .linear: return .linear(duration: duration)
            case .easeIn: return .easeIn(duration: duration)
            case .easeOut: return .easeOut(duration: duration)
            case .easeInOut: return .easeInOut(duration: duration)
            case .spring(let response, let damping):
                return .spring(response: response, dampingFraction: damping)
            }
        }
    }
}

// MARK: - Usage
struct AnimatedButton: View {
    @State private var isPressed = false
    
    var body: some View {
        Button("Tap Me") {
            isPressed.toggle()
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(DesignTokens.AnimationTiming.fast.animation, value: isPressed)
    }
}
```

---

## Step 4: Icon System

### File: `Design/DesignTokens+Icons.swift`
```swift
import SwiftUI

extension DesignTokens {
    /// Icon system - semantic icons
    enum Icon {
        // MARK: - Navigation
        case home
        case trends
        case activities
        case profile
        case settings
        
        // MARK: - Actions
        case add
        case edit
        case delete
        case share
        case close
        case back
        case forward
        
        // MARK: - Status
        case success
        case warning
        case error
        case info
        
        // MARK: - Metrics
        case heart
        case sleep
        case recovery
        case strain
        case power
        
        var systemName: String {
            switch self {
            // Navigation
            case .home: return "house.fill"
            case .trends: return "chart.line.uptrend.xyaxis"
            case .activities: return "figure.run"
            case .profile: return "person.circle.fill"
            case .settings: return "gearshape.fill"
            
            // Actions
            case .add: return "plus.circle.fill"
            case .edit: return "pencil.circle.fill"
            case .delete: return "trash.fill"
            case .share: return "square.and.arrow.up"
            case .close: return "xmark.circle.fill"
            case .back: return "chevron.left"
            case .forward: return "chevron.right"
            
            // Status
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            
            // Metrics
            case .heart: return "heart.fill"
            case .sleep: return "bed.double.fill"
            case .recovery: return "arrow.clockwise"
            case .strain: return "flame.fill"
            case .power: return "bolt.fill"
            }
        }
        
        func image(size: Size = .medium) -> Image {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.value, height: size.value)
        }
        
        enum Size {
            case small    // 16pt
            case medium   // 24pt
            case large    // 32pt
            case extraLarge // 48pt
            
            var value: CGFloat {
                switch self {
                case .small: return 16
                case .medium: return 24
                case .large: return 32
                case .extraLarge: return 48
                }
            }
        }
    }
}

// MARK: - Usage
struct IconExamples: View {
    var body: some View {
        HStack(spacing: 16) {
            DesignTokens.Icon.heart.image(size: .small)
            DesignTokens.Icon.sleep.image(size: .medium)
            DesignTokens.Icon.recovery.image(size: .large)
        }
    }
}
```

---

## Step 5: Complete Color System

### File: `Design/DesignTokens+Colors.swift` (Enhanced)
```swift
import SwiftUI

extension DesignTokens {
    enum Colors {
        // MARK: - Semantic Colors (Already have these)
        static let optimal = Color("OptimalGreen")
        static let good = Color("GoodBlue")
        static let fair = Color("FairOrange")
        static let poor = Color("PoorRed")
        
        // MARK: - Add Status Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // MARK: - Add Surface Colors
        static let surface = Color(uiColor: .systemBackground)
        static let surfaceVariant = Color(uiColor: .secondarySystemBackground)
        static let surfaceTertiary = Color(uiColor: .tertiarySystemBackground)
        
        // MARK: - Add Border Colors
        static let border = Color(uiColor: .separator)
        static let borderStrong = Color(uiColor: .opaqueSeparator)
        
        // MARK: - Add Text Colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        static let textDisabled = Color(uiColor: .quaternaryLabel)
        
        // MARK: - Chart Colors (for trends)
        static let chartPrimary = Color.blue
        static let chartSecondary = Color.purple
        static let chartTertiary = Color.orange
        static let chartGrid = Color.gray.opacity(0.2)
    }
}
```

---

## Step 6: Audit & Fix Hard-coded Values

### Audit Script
```bash
#!/bin/bash
# Find hard-coded values in Swift files

echo "🔍 Auditing design tokens usage..."
echo ""

echo "❌ Hard-coded colors:"
grep -r "Color\\.blue\\|Color\\.red\\|Color\\.green" --include="*.swift" VeloReady/ | wc -l

echo "❌ Hard-coded spacing:"
grep -r "\\.padding([0-9]" --include="*.swift" VeloReady/ | wc -l

echo "❌ Hard-coded font sizes:"
grep -r "size: [0-9]" --include="*.swift" VeloReady/ | wc -l

echo "❌ Hard-coded shadows:"
grep -r "shadow(color:" --include="*.swift" VeloReady/ | wc -l

echo ""
echo "Run: sh scripts/fix-design-tokens.sh to see details"
```

### Common Fixes

#### **Before (Hard-coded):**
```swift
Text("Recovery Score")
    .font(.system(size: 16, weight: .semibold))
    .foregroundColor(.blue)
    .padding(12)
    .background(
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    )
```

#### **After (Design Tokens):**
```swift
Text("Recovery Score")
    .typography(.titleMedium)
    .foregroundColor(DesignTokens.Colors.textPrimary)
    .padding(DesignTokens.Spacing.md)
    .background(
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
            .fill(DesignTokens.Colors.surface)
            .elevation(.medium)
    )
```

---

## Step 7: Design Documentation

### File: `DESIGN_SYSTEM.md`
```markdown
# VeloReady Design System

## Overview
Complete design token system for consistent UI across the app.

## Typography

### Display Styles
- **Display Large:** 57pt Bold - Hero sections
- **Display Medium:** 45pt Bold - Large headings
- **Display Small:** 36pt Bold - Section headers

### Usage
```swift
Text("Welcome").typography(.displayLarge)
```

## Colors

### Semantic Colors
- **Optimal Green** - Recovery 80-100
- **Good Blue** - Recovery 60-79
- **Fair Orange** - Recovery 40-59
- **Poor Red** - Recovery 0-39

### Usage
```swift
Text("Score").foregroundColor(DesignTokens.Colors.optimal)
```

## Spacing
- **xs:** 4pt - Tight spacing
- **sm:** 8pt - Compact spacing
- **md:** 16pt - Standard spacing
- **lg:** 24pt - Loose spacing
- **xl:** 32pt - Very loose spacing
- **xxl:** 48pt - Section spacing

## Shadows
- **Small:** Subtle depth for inline elements
- **Medium:** Standard card elevation
- **Large:** Modal/sheet elevation
- **Extra Large:** Floating action buttons

## Animations
- **Fast:** 0.15s - Quick feedback
- **Normal:** 0.3s - Standard transitions
- **Slow:** 0.5s - Deliberate movements

## Dark Mode
All tokens automatically adapt to dark mode via semantic colors.
```

---

## Step 8: Figma Sync (Optional)

### Token Export from Figma
```json
{
  "colors": {
    "optimal": "#4CAF50",
    "good": "#2196F3",
    "fair": "#FF9800",
    "poor": "#F44336"
  },
  "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24,
    "xl": 32
  },
  "typography": {
    "displayLarge": {
      "size": 57,
      "weight": "bold",
      "lineHeight": 64
    }
  }
}
```

### Swift Generation Script
```swift
// scripts/generate-tokens.swift
// Reads tokens.json and generates DesignTokens.swift
```

---

## Success Metrics

### Code Quality
- [ ] **Zero hard-coded colors** in views
- [ ] **Zero hard-coded spacing** values
- [ ] **Zero hard-coded font sizes**
- [ ] **100% design token usage**

### Design Consistency
- [ ] **All components** use typography system
- [ ] **All cards** use shadow system
- [ ] **All animations** use timing system
- [ ] **All icons** use semantic names

### Documentation
- [ ] **Design system docs** complete
- [ ] **Component usage examples**
- [ ] **Figma sync** (optional)
- [ ] **Token migration guide**

---

## Timeline

**Week 9:**
- Day 1: Create typography, shadow, animation systems
- Day 2: Audit hard-coded values across app
- Day 3: Fix all hard-coded values (batch edits)
- Day 4: Write design system documentation
- Day 5: Review, test dark mode, deploy

---

## Final Architecture Status

After completing all 5 phases:

✅ **Phase 1:** Unified networking & caching  
✅ **Phase 2:** Service consolidation (24 → 8)  
✅ **Phase 3:** Component system (40 → 15)  
✅ **Phase 4:** MVVM architecture (views 80% smaller)  
✅ **Phase 5:** Design system (100% token usage)  

**Result:** World-class, maintainable, scalable iOS architecture! 🎉
