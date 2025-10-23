# VeloReady Spacing Guidelines
## Design System Spacing Tokens

**Last Updated:** October 23, 2025  
**Status:** ✅ **ENFORCED**

---

## 📏 **SPACING TOKENS**

### **Standard Spacing Scale**

VeloReady uses a consistent spacing scale defined in `Spacing.swift`:

| Token | Value | Usage |
|-------|-------|-------|
| `Spacing.xs` | 4pt | Tight spacing (icons, badges, inline elements) |
| `Spacing.sm` | 8pt | Compact spacing (list items, compact cards) |
| `Spacing.md` | 12pt | Standard spacing (card content, sections) |
| `Spacing.lg` | 16pt | Generous spacing (between cards, major sections) |
| `Spacing.xl` | 20pt | Large spacing (page margins, major separators) |
| `Spacing.xxl` | 24pt | Extra large spacing (page headers, major sections) |

### **Component-Specific Sizes**

Defined in `ComponentSizes.swift`:

```swift
// Ring Components
ComponentSizes.ringWidthLarge: 12pt     // Large recovery rings
ComponentSizes.ringWidthSmall: 8pt      // Compact rings
ComponentSizes.ringDiameterLarge: 160pt // Large ring diameter
ComponentSizes.ringDiameterSmall: 80pt  // Compact ring diameter
ComponentSizes.ringDiameterEmpty: 100pt // Empty state rings

// Corner Radius
ComponentSizes.cornerRadiusSmall: 8pt   // Pills, badges
ComponentSizes.cornerRadiusMedium: 12pt // Cards
ComponentSizes.cornerRadiusLarge: 16pt  // Sheets

// Icon Sizes
ComponentSizes.iconSmall: 16pt          // Badges, indicators
ComponentSizes.iconMedium: 24pt         // Cards
ComponentSizes.iconLarge: 40pt          // Headers, empty states
```

---

## ✅ **CORRECT USAGE**

### **VStack/HStack Spacing**

```swift
// ✅ CORRECT - Use spacing tokens
VStack(spacing: Spacing.md) {
    Text("Title")
    Text("Subtitle")
}

HStack(spacing: Spacing.xs) {
    Image(systemName: "heart.fill")
    Text("Recovery")
}
```

### **Padding**

```swift
// ✅ CORRECT - Use spacing tokens
.padding(.horizontal, Spacing.lg)
.padding(.top, Spacing.sm)
.padding(.bottom, Spacing.md)
```

### **Component Sizes**

```swift
// ✅ CORRECT - Use ComponentSizes
private let ringWidth: CGFloat = ComponentSizes.ringWidthLarge
private let size: CGFloat = ComponentSizes.ringDiameterLarge
```

---

## ❌ **INCORRECT USAGE**

### **Hard-Coded Values**

```swift
// ❌ WRONG - Hard-coded spacing
VStack(spacing: 4) {  // Should be Spacing.xs
    Text("Title")
}

HStack(spacing: 12) {  // Should be Spacing.md
    Image(systemName: "icon")
}

// ❌ WRONG - Hard-coded padding
.padding(.horizontal, 16)  // Should be Spacing.lg
.padding(.top, 8)          // Should be Spacing.sm

// ❌ WRONG - Magic numbers
private let ringWidth: CGFloat = 12  // Should be ComponentSizes.ringWidthLarge
private let size: CGFloat = 160      // Should be ComponentSizes.ringDiameterLarge
```

---

## 🎯 **SPACING DECISION TREE**

### **When to use each token:**

**Spacing.xs (4pt):**
- Icon + text inline spacing
- Badge internal spacing
- Tight element grouping
- Indicator spacing

**Spacing.sm (8pt):**
- Compact list items
- Ring view title spacing
- Small card internal spacing
- Compact component spacing

**Spacing.md (12pt):**
- Standard card content spacing
- Section spacing within cards
- Default VStack/HStack spacing
- Form field spacing

**Spacing.lg (16pt):**
- Between cards in a list
- Major section separators
- Card padding
- Preview spacing

**Spacing.xl (20pt):**
- Page-level margins
- Major content separators
- Large section spacing

**Spacing.xxl (24pt):**
- Page headers
- Major feature sections
- Modal/sheet spacing

---

## 📋 **MIGRATION CHECKLIST**

When creating or updating a component:

- [ ] Replace all `spacing: [number]` with `Spacing.*` tokens
- [ ] Replace all `.padding([number])` with `Spacing.*` tokens
- [ ] Extract magic numbers to `ComponentSizes`
- [ ] Use semantic token names (xs, sm, md, lg, xl, xxl)
- [ ] Verify build succeeds
- [ ] Check visual consistency

---

## 🔍 **FINDING HARD-CODED VALUES**

### **Search for Hard-Coded Spacing:**

```bash
# Find hard-coded spacing in VStack/HStack
grep -r "spacing: [0-9]" --include="*.swift" VeloReady/Features

# Find hard-coded padding
grep -r "\.padding([0-9]" --include="*.swift" VeloReady/Features

# Find magic numbers in component sizes
grep -r "CGFloat = [0-9]" --include="*.swift" VeloReady/Features
```

---

## 🎨 **DESIGN PRINCIPLES**

### **1. Consistency**
All spacing should use tokens to ensure visual consistency across the app.

### **2. Scalability**
Spacing tokens allow global adjustments without touching individual components.

### **3. Predictability**
Developers know exactly which spacing values are available.

### **4. Maintainability**
Single source of truth for all spacing values.

---

## 📚 **EXAMPLES**

### **Card Component**

```swift
struct MyCard: View {
    var body: some View {
        CardContainer(
            header: CardHeader(title: "Title")
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "icon")
                    Text("Label")
                }
                
                Divider()
                    .padding(.vertical, Spacing.sm)
                
                Text("Content")
            }
        }
    }
}
```

### **Ring Component**

```swift
struct MyRing: View {
    private let ringWidth: CGFloat = ComponentSizes.ringWidthLarge
    private let size: CGFloat = ComponentSizes.ringDiameterLarge
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(lineWidth: ringWidth)
                    .frame(width: size, height: size)
                
                VStack(spacing: Spacing.xs) {
                    Text("Score")
                    Text("Label")
                }
            }
            
            Text("Title")
        }
    }
}
```

### **List Component**

```swift
struct MyList: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(items) { item in
                ItemCard(item: item)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
}
```

---

## 🚫 **ANTI-PATTERNS**

### **Don't Mix Tokens and Hard-Coded Values**

```swift
// ❌ BAD - Inconsistent
VStack(spacing: Spacing.md) {
    HStack(spacing: 8) {  // Hard-coded!
        Text("Mixed")
    }
}

// ✅ GOOD - Consistent
VStack(spacing: Spacing.md) {
    HStack(spacing: Spacing.sm) {
        Text("Consistent")
    }
}
```

### **Don't Calculate Spacing**

```swift
// ❌ BAD - Calculated spacing
.padding(Spacing.md * 2)  // Use Spacing.xxl instead

// ✅ GOOD - Use appropriate token
.padding(Spacing.xxl)
```

### **Don't Use Arbitrary Values**

```swift
// ❌ BAD - Arbitrary value
VStack(spacing: 14) {  // Not in our scale!
    ...
}

// ✅ GOOD - Use closest token
VStack(spacing: Spacing.md) {  // 12pt
    ...
}
```

---

## 📖 **REFERENCE**

### **Quick Reference Card**

```
xs  = 4pt   → Icon spacing, badges
sm  = 8pt   → Compact lists, small cards
md  = 12pt  → Standard spacing (default)
lg  = 16pt  → Between cards
xl  = 20pt  → Page margins
xxl = 24pt  → Major sections
```

### **Related Files**

- `/Core/Design/Spacing.swift` - Spacing token definitions
- `/Core/Design/ComponentSizes.swift` - Component size constants
- `/Design/Organisms/ChartCard.swift` - Example usage
- `/Design/Organisms/CardContainer.swift` - Example usage

---

## ✅ **ENFORCEMENT**

### **Code Review Checklist**

- [ ] No hard-coded spacing values
- [ ] No hard-coded padding values
- [ ] No magic numbers for component sizes
- [ ] All spacing uses tokens
- [ ] Build succeeds
- [ ] Visual consistency maintained

### **Automated Checks**

See `LINTING_RULES.md` for automated linting rules to prevent hard-coded values.

---

**Questions?** Refer to the design system documentation or ask the team.

**Last Audit:** October 23, 2025 - ✅ All components compliant
