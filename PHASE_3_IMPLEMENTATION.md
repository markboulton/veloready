c# Phase 3 Implementation Guide: Component System Modernization

**Goal:** Create composable, reusable UI components  
**Timeline:** Week 5-6 (2 weeks)  
**Status:** Ready to implement  
**Prerequisites:** Phase 1 & 2 complete

---

## Executive Summary

Currently VeloReady has **40+ card components** with significant duplication. Many follow the StandardCard pattern, but implementation varies. This phase consolidates components using **composition over inheritance** and creates a **component library**.

### Current Issues
- ❌ **40+ card components** with overlapping functionality
- ❌ **Duplicate layouts** - Similar header/body/footer patterns
- ❌ **Inconsistent spacing** - Some components bypass design tokens
- ❌ **Hard to maintain** - Changes require updating multiple files
- ❌ **No component docs** - Unclear which component to use

### Phase 3 Goals
✅ Reduce to **12-15 composable components**  
✅ **50% code reduction** in component files  
✅ **100% design token usage** - Zero hard-coded values  
✅ **Component library** with usage examples  
✅ **Unit tests** for all base components  

---

## Step 1: Atomic Design System

### File Structure
```
VeloReady/Design/
├── Atoms/              ← NEW
│   ├── VRText.swift
│   ├── VRButton.swift
│   ├── VRIcon.swift
│   ├── VRBadge.swift
│   └── VRDivider.swift
├── Molecules/          ← NEW
│   ├── CardHeader.swift
│   ├── CardMetric.swift
│   ├── CardFooter.swift
│   └── StatRow.swift
└── Organisms/          ← REFACTOR
    ├── CardContainer.swift
    ├── MetricCard.swift
    ├── ChartCard.swift
    └── ActivityCard.swift
```

### Implementation: Atomic Components

#### **Atoms/VRText.swift**
```swift
import SwiftUI

/// Atomic text component - all text should use this
struct VRText: View {
    let text: String
    let style: Style
    let color: Color?
    
    enum Style {
        case largeTitle
        case title
        case title2
        case title3
        case headline
        case body
        case bodySecondary
        case caption
        case caption2
        
        var font: Font {
            switch self {
            case .largeTitle: return .system(size: 34, weight: .bold)
            case .title: return .system(size: 28, weight: .bold)
            case .title2: return .system(size: 22, weight: .bold)
            case .title3: return .system(size: 20, weight: .semibold)
            case .headline: return .system(size: 17, weight: .semibold)
            case .body: return .system(size: 17, weight: .regular)
            case .bodySecondary: return .system(size: 15, weight: .regular)
            case .caption: return .system(size: 13, weight: .regular)
            case .caption2: return .system(size: 11, weight: .regular)
            }
        }
        
        var defaultColor: Color {
            switch self {
            case .bodySecondary, .caption, .caption2:
                return .secondary
            default:
                return .primary
            }
        }
    }
    
    init(_ text: String, style: Style = .body, color: Color? = nil) {
        self.text = text
        self.style = style
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(style.font)
            .foregroundColor(color ?? style.defaultColor)
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading, spacing: 16) {
        VRText("Large Title", style: .largeTitle)
        VRText("Title", style: .title)
        VRText("Headline", style: .headline)
        VRText("Body Text", style: .body)
        VRText("Secondary Body", style: .bodySecondary)
        VRText("Caption", style: .caption)
    }
    .padding()
}
```

#### **Atoms/VRBadge.swift**
```swift
import SwiftUI

/// Atomic badge component - consistent badge styling
struct VRBadge: View {
    let text: String
    let style: Style
    
    enum Style {
        case success
        case warning
        case error
        case info
        case neutral
        
        var backgroundColor: Color {
            switch self {
            case .success: return .green.opacity(0.2)
            case .warning: return .orange.opacity(0.2)
            case .error: return .red.opacity(0.2)
            case .info: return .blue.opacity(0.2)
            case .neutral: return .gray.opacity(0.2)
            }
        }
        
        var textColor: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            case .neutral: return .gray
            }
        }
    }
    
    init(_ text: String, style: Style = .neutral) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(style.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(style.backgroundColor)
            )
    }
}
```

---

## Step 2: Molecular Components

### **Molecules/CardHeader.swift**
```swift
import SwiftUI

/// Composable card header - used by all cards
struct CardHeader: View {
    let title: String
    let subtitle: String?
    let badge: Badge?
    let action: Action?
    
    struct Badge {
        let text: String
        let style: VRBadge.Style
    }
    
    struct Action {
        let icon: String
        let action: () -> Void
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        badge: Badge? = nil,
        action: Action? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    VRText(title, style: .headline)
                    
                    if let badge = badge {
                        VRBadge(badge.text, style: badge.style)
                    }
                }
                
                if let subtitle = subtitle {
                    VRText(subtitle, style: .caption, color: .secondary)
                }
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action.action) {
                    Image(systemName: action.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CardHeader(title: "Recovery Score")
        
        CardHeader(
            title: "Sleep Quality",
            subtitle: "Last 7 days"
        )
        
        CardHeader(
            title: "Training Load",
            badge: .init(text: "HIGH", style: .warning)
        )
        
        CardHeader(
            title: "Heart Rate",
            subtitle: "Overnight average",
            action: .init(icon: "chevron.right", action: {})
        )
    }
    .padding()
}
```

### **Molecules/CardMetric.swift**
```swift
import SwiftUI

/// Composable metric display - consistent across all cards
struct CardMetric: View {
    let value: String
    let label: String
    let change: Change?
    let size: Size
    
    struct Change {
        let value: String
        let direction: Direction
        
        enum Direction {
            case up
            case down
            case neutral
            
            var color: Color {
                switch self {
                case .up: return .green
                case .down: return .red
                case .neutral: return .gray
                }
            }
            
            var icon: String {
                switch self {
                case .up: return "arrow.up"
                case .down: return "arrow.down"
                case .neutral: return "minus"
                }
            }
        }
    }
    
    enum Size {
        case large
        case medium
        case small
        
        var valueFont: Font {
            switch self {
            case .large: return .system(size: 48, weight: .bold, design: .rounded)
            case .medium: return .system(size: 32, weight: .bold, design: .rounded)
            case .small: return .system(size: 24, weight: .semibold, design: .rounded)
            }
        }
        
        var labelFont: Font {
            switch self {
            case .large: return .system(size: 15)
            case .medium: return .system(size: 13)
            case .small: return .system(size: 11)
            }
        }
    }
    
    init(
        value: String,
        label: String,
        change: Change? = nil,
        size: Size = .medium
    ) {
        self.value = value
        self.label = label
        self.change = change
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(size.valueFont)
                    .foregroundColor(.primary)
                
                if let change = change {
                    HStack(spacing: 2) {
                        Image(systemName: change.direction.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(change.value)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(change.direction.color)
                }
            }
            
            Text(label)
                .font(size.labelFont)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        CardMetric(
            value: "92",
            label: "Recovery Score",
            change: .init(value: "+5", direction: .up),
            size: .large
        )
        
        CardMetric(
            value: "7.2h",
            label: "Sleep Duration",
            change: .init(value: "-0.3h", direction: .down),
            size: .medium
        )
        
        CardMetric(
            value: "65 bpm",
            label: "Resting Heart Rate",
            size: .small
        )
    }
    .padding()
}
```

---

## Step 3: Organism Components

### **Organisms/CardContainer.swift**
```swift
import SwiftUI

/// Universal card container - replaces StandardCard
struct CardContainer<Content: View>: View {
    let header: CardHeader?
    let footer: CardFooter?
    let style: Style
    let content: () -> Content
    
    enum Style {
        case standard
        case compact
        case hero
        
        var padding: EdgeInsets {
            switch self {
            case .standard: return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            case .compact: return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            case .hero: return EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .standard: return 16
            case .compact: return 12
            case .hero: return 20
            }
        }
    }
    
    init(
        header: CardHeader? = nil,
        footer: CardFooter? = nil,
        style: Style = .standard,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.style = style
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let header = header {
                header
            }
            
            content()
            
            if let footer = footer {
                footer
            }
        }
        .padding(style.padding)
        .background(
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

struct CardFooter: View {
    let text: String?
    let action: Action?
    
    struct Action {
        let label: String
        let action: () -> Void
    }
    
    init(text: String? = nil, action: Action? = nil) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        HStack {
            if let text = text {
                VRText(text, style: .caption, color: .secondary)
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action.action) {
                    Text(action.label)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Simple card
        CardContainer {
            VRText("Simple card content", style: .body)
        }
        
        // Card with header
        CardContainer(
            header: CardHeader(title: "Recovery Score")
        ) {
            CardMetric(
                value: "92",
                label: "Optimal Recovery",
                size: .large
            )
        }
        
        // Full card
        CardContainer(
            header: CardHeader(
                title: "Training Load",
                subtitle: "Last 7 days",
                badge: .init(text: "HIGH", style: .warning)
            ),
            footer: CardFooter(
                text: "Updated 5 min ago",
                action: .init(label: "View Details", action: {})
            )
        ) {
            HStack(spacing: 20) {
                CardMetric(value: "245", label: "CTL", size: .medium)
                CardMetric(value: "89", label: "ATL", size: .medium)
                CardMetric(value: "+12", label: "TSB", size: .medium)
            }
        }
    }
    .padding()
}
```

---

## Step 4: Migration Strategy

### Phase 3A: Create Foundation (Week 5, Day 1-2)
1. ✅ Create `Design/Atoms/` folder
2. ✅ Implement VRText, VRButton, VRBadge, VRIcon
3. ✅ Create `Design/Molecules/` folder
4. ✅ Implement CardHeader, CardMetric, CardFooter
5. ✅ Create `Design/Organisms/` folder
6. ✅ Implement CardContainer
7. ✅ Add unit tests for all components

### Phase 3B: Migrate Cards (Week 5, Day 3-5)
Pick **5 high-use cards** to migrate first:

#### **Priority 1: RecoveryCard**
**Before (current):**
```swift
// RecoveryCard.swift - 120 lines
struct RecoveryCard: View {
    let score: Int
    let trend: String
    
    var body: some View {
        StandardCard {
            VStack {
                // Custom header implementation
                HStack {
                    Text("Recovery Score")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                // Custom metric display
                Text("\(score)")
                    .font(.system(size: 48))
                // Custom footer
                Text("Trend: \(trend)")
            }
        }
    }
}
```

**After (new):**
```swift
// RecoveryCard.swift - 30 lines
struct RecoveryCard: View {
    let score: Int
    let trend: String
    let change: Int
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: CommonContent.recovery.title,
                badge: badge(for: score)
            ),
            footer: CardFooter(
                text: "Trend: \(trend)",
                action: .init(label: "View Details", action: { })
            )
        ) {
            CardMetric(
                value: "\(score)",
                label: band(for: score),
                change: .init(
                    value: formatChange(change),
                    direction: changeDirection(change)
                ),
                size: .large
            )
        }
    }
    
    private func badge(for score: Int) -> CardHeader.Badge? {
        if score >= 80 { return .init(text: "OPTIMAL", style: .success) }
        if score >= 60 { return .init(text: "GOOD", style: .info) }
        return .init(text: "LOW", style: .warning)
    }
}
```

**Result:** 75% code reduction, fully composable

### Cards to Migrate (Priority Order):
1. ✅ **RecoveryCard** - High visibility, simple structure
2. ✅ **SleepCard** - Similar to RecoveryCard
3. ✅ **StrainCard** - Metric + chart pattern
4. ✅ **ActivityCard** - Complex layout, big impact
5. ✅ **WellnessCard** - Multiple metrics pattern

### Phase 3C: Delete Duplicates (Week 6, Day 1-2)
After migration, delete old implementations:
```bash
# Example deletions
rm RecoveryCardOld.swift
rm SleepCardV1.swift
rm CustomMetricDisplay.swift
```

**Expected Reductions:**
- Delete 15-20 duplicate card files
- Reduce component code by 50%
- Consolidate to 12-15 composable components

---

## Step 5: Component Library Documentation

### File: `COMPONENT_LIBRARY.md`
```markdown
# VeloReady Component Library

## Atoms
- **VRText** - All text rendering
- **VRButton** - All button interactions
- **VRBadge** - Status badges
- **VRIcon** - Icon rendering

## Molecules
- **CardHeader** - Card title + subtitle + badge
- **CardMetric** - Value + label + change indicator
- **CardFooter** - Caption + action button

## Organisms
- **CardContainer** - Universal card wrapper
- **MetricCard** - Single metric display
- **ChartCard** - Chart + header + footer
- **ActivityCard** - Activity row with map

## Usage Examples
[Include screenshots and code samples]
```

---

## Step 6: Testing Strategy

### Unit Tests: `Tests/ComponentTests/`
```swift
import XCTest
@testable import VeloReady

class CardMetricTests: XCTestCase {
    func testMetricRendersValue() {
        let metric = CardMetric(
            value: "92",
            label: "Score",
            size: .large
        )
        // Assert value is displayed
    }
    
    func testChangeIndicatorColor() {
        let upChange = CardMetric.Change(value: "+5", direction: .up)
        XCTAssertEqual(upChange.direction.color, .green)
        
        let downChange = CardMetric.Change(value: "-3", direction: .down)
        XCTAssertEqual(downChange.direction.color, .red)
    }
}
```

---

## Success Metrics

### Code Reduction
- [ ] **40 card files** → **15 composable components** (-62%)
- [ ] **~8,000 lines** → **~4,000 lines** (-50%)
- [ ] **Zero hard-coded backgrounds** (100% design tokens)

### Quality Improvements
- [ ] **100% component test coverage**
- [ ] **Component library documented** with examples
- [ ] **Figma alignment** - Components match design system
- [ ] **Accessibility** - VoiceOver support for all components

### Developer Experience
- [ ] **New card in 20 lines** (vs 120 before)
- [ ] **Consistent API** across all cards
- [ ] **Easy to customize** via composition
- [ ] **Type-safe** - Compiler catches issues

---

## Timeline

**Week 5:**
- Day 1-2: Create atomic/molecular components
- Day 3-5: Migrate 5 priority cards

**Week 6:**
- Day 1-2: Delete duplicates, consolidate
- Day 3-4: Component tests + documentation
- Day 5: Review, polish, deploy

---

## Next Phase

After Phase 3 completes, move to **Phase 4: View Architecture** where we'll:
- Extract view logic to view models
- Slim down TodayView (814 lines → ~200 lines)
- Make all business logic testable
- Clear separation of concerns

**Ready to implement Phase 3?** Start with Step 1: Create atomic components!
