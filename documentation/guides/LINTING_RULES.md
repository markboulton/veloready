# VeloReady Linting Rules
## Automated Code Quality Enforcement

**Last Updated:** October 23, 2025  
**Status:** ✅ **DOCUMENTED**

---

## 🎯 **OVERVIEW**

This document defines linting rules to enforce VeloReady's design system and architecture patterns.

---

## 📏 **SPACING & DESIGN TOKENS**

### **Rule 1: No Hard-Coded Spacing in VStack/HStack**

**Pattern to Detect:**
```regex
(VStack|HStack)\(.*spacing:\s*\d+
```

**Examples:**
```swift
// ❌ VIOLATION
VStack(spacing: 4) { ... }
HStack(spacing: 12) { ... }

// ✅ COMPLIANT
VStack(spacing: Spacing.xs) { ... }
HStack(spacing: Spacing.md) { ... }
```

**Enforcement:**
```bash
# Search for violations
grep -rn "VStack.*spacing:\s*[0-9]" --include="*.swift" VeloReady/Features
grep -rn "HStack.*spacing:\s*[0-9]" --include="*.swift" VeloReady/Features
```

**Fix:**
Replace with appropriate `Spacing.*` token (xs, sm, md, lg, xl, xxl).

---

### **Rule 2: No Hard-Coded Padding Values**

**Pattern to Detect:**
```regex
\.padding\(\s*\d+\s*\)
\.padding\(\.(horizontal|vertical|top|bottom|leading|trailing),\s*\d+\s*\)
```

**Examples:**
```swift
// ❌ VIOLATION
.padding(16)
.padding(.horizontal, 12)
.padding(.top, 8)

// ✅ COMPLIANT
.padding(Spacing.lg)
.padding(.horizontal, Spacing.md)
.padding(.top, Spacing.sm)
```

**Enforcement:**
```bash
# Search for violations
grep -rn "\.padding([0-9]" --include="*.swift" VeloReady/Features
grep -rn "\.padding(\.(horizontal|vertical|top|bottom|leading|trailing),\s*[0-9]" --include="*.swift" VeloReady/Features
```

**Fix:**
Replace with appropriate `Spacing.*` token.

---

### **Rule 3: No Magic Numbers for Component Sizes**

**Pattern to Detect:**
```regex
(private|let)\s+(let|var)\s+\w+:\s*CGFloat\s*=\s*\d+
```

**Examples:**
```swift
// ❌ VIOLATION
private let ringWidth: CGFloat = 12
private let size: CGFloat = 160

// ✅ COMPLIANT
private let ringWidth: CGFloat = ComponentSizes.ringWidthLarge
private let size: CGFloat = ComponentSizes.ringDiameterLarge
```

**Enforcement:**
```bash
# Search for violations
grep -rn "CGFloat\s*=\s*[0-9]" --include="*.swift" VeloReady/Features
```

**Exceptions:**
- Animation durations (e.g., `duration: 0.3`)
- Opacity values (e.g., `opacity: 0.5`)
- Percentages (e.g., `0.8`)
- Mathematical calculations (e.g., `Double(score) / 100.0`)

**Fix:**
Extract to `ComponentSizes.swift` or use existing token.

---

## 🎨 **ATOMIC DESIGN**

### **Rule 4: Cards Must Use Atomic Wrappers**

**Required Wrappers:**
- `ChartCard` for charts
- `CardContainer` for general cards
- `ScoreCard` for score displays
- `StandardCard` for simple content

**Examples:**
```swift
// ❌ VIOLATION
struct MyCard: View {
    var body: some View {
        VStack {
            HStack {
                Text("Title")
                Spacer()
            }
            // ... content
        }
        .padding()
        .background(Color.background.secondary)
    }
}

// ✅ COMPLIANT
struct MyCard: View {
    var body: some View {
        CardContainer(
            header: CardHeader(title: "Title")
        ) {
            // ... content
        }
    }
}
```

**Enforcement:**
Manual code review - look for manual card layouts.

---

### **Rule 5: No Manual Card Headers**

**Pattern to Detect:**
```swift
// Manual header pattern
HStack {
    Text("Title")
        .font(.headline)
    Spacer()
}
```

**Examples:**
```swift
// ❌ VIOLATION
VStack {
    HStack {
        Text("My Card")
            .font(.headline)
        Spacer()
    }
    // content
}

// ✅ COMPLIANT
CardContainer(
    header: CardHeader(title: "My Card")
) {
    // content
}
```

**Enforcement:**
Manual code review - all cards should use `CardHeader`.

---

## 🏗️ **MVVM ARCHITECTURE**

### **Rule 6: No Business Logic in Views**

**Violations:**
- Data fetching in views
- Complex calculations in views
- State management beyond UI state

**Examples:**
```swift
// ❌ VIOLATION
struct MyView: View {
    var body: some View {
        let data = fetchDataFromAPI()  // Business logic!
        let score = calculateComplexScore(data)  // Business logic!
        
        Text("\(score)")
    }
}

// ✅ COMPLIANT
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        Text("\(viewModel.score)")
    }
}
```

**Enforcement:**
Manual code review - views should only contain UI logic.

---

### **Rule 7: ViewModels Must Be @MainActor**

**Pattern:**
```swift
@MainActor
class MyViewModel: ObservableObject {
    // ...
}
```

**Examples:**
```swift
// ❌ VIOLATION
class MyViewModel: ObservableObject {
    @Published var data: [Item] = []
}

// ✅ COMPLIANT
@MainActor
class MyViewModel: ObservableObject {
    @Published var data: [Item] = []
}
```

**Enforcement:**
```bash
# Find ViewModels without @MainActor
grep -B2 "class.*ViewModel.*ObservableObject" --include="*.swift" VeloReady/Features | grep -v "@MainActor"
```

---

## 📝 **CONTENT ABSTRACTION**

### **Rule 8: No Hard-Coded Strings**

**Pattern to Detect:**
```swift
Text("Hard-coded string")
```

**Examples:**
```swift
// ❌ VIOLATION
Text("Recovery Score")
Text("No data available")

// ✅ COMPLIANT
Text(TodayContent.recovery)
Text(CommonContent.States.noDataFound)
```

**Exceptions:**
- Debug/logging strings
- Preview content
- Developer-only strings

**Enforcement:**
```bash
# Find hard-coded strings (excluding common patterns)
grep -rn 'Text("' --include="*.swift" VeloReady/Features | grep -v "Content\."
```

**Fix:**
Add to appropriate `*Content.swift` file.

---

## 🎨 **COLOR USAGE**

### **Rule 9: Use Color Tokens**

**Required:**
- `Color.text.*` for text colors
- `Color.background.*` for backgrounds
- `ColorScale.*` for semantic colors
- `Color.health.*`, `Color.workout.*` for domain colors

**Examples:**
```swift
// ❌ VIOLATION
.foregroundColor(.gray)
.background(Color(red: 0.9, green: 0.9, blue: 0.9))

// ✅ COMPLIANT
.foregroundColor(Color.text.secondary)
.background(Color.background.secondary)
```

**Enforcement:**
Manual code review - avoid raw color values.

---

## 🔧 **AUTOMATED LINTING SETUP**

### **SwiftLint Configuration**

Add to `.swiftlint.yml`:

```yaml
custom_rules:
  hard_coded_spacing:
    name: "Hard-coded Spacing"
    regex: '(VStack|HStack)\(.*spacing:\s*\d+'
    message: "Use Spacing.* tokens instead of hard-coded values"
    severity: warning
    
  hard_coded_padding:
    name: "Hard-coded Padding"
    regex: '\.padding\(\s*\d+\s*\)'
    message: "Use Spacing.* tokens instead of hard-coded padding"
    severity: warning
    
  magic_numbers_cgfloat:
    name: "Magic Numbers in CGFloat"
    regex: 'CGFloat\s*=\s*\d+'
    message: "Extract to ComponentSizes or use design token"
    severity: warning
    
  hard_coded_strings:
    name: "Hard-coded Strings"
    regex: 'Text\("[^"]+"\)'
    message: "Use *Content.* strings instead of hard-coded text"
    severity: warning
```

### **Pre-Commit Hook**

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "Running VeloReady linting checks..."

# Check for hard-coded spacing
if git diff --cached --name-only | grep "\.swift$" | xargs grep -n "spacing:\s*[0-9]" 2>/dev/null; then
    echo "❌ Found hard-coded spacing values. Use Spacing.* tokens."
    exit 1
fi

# Check for hard-coded padding
if git diff --cached --name-only | grep "\.swift$" | xargs grep -n "\.padding([0-9]" 2>/dev/null; then
    echo "❌ Found hard-coded padding values. Use Spacing.* tokens."
    exit 1
fi

echo "✅ Linting checks passed!"
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## 📊 **VERIFICATION SCRIPTS**

### **Check All Rules**

Create `scripts/lint-check.sh`:

```bash
#!/bin/bash

echo "🔍 VeloReady Linting Check"
echo "=========================="

VIOLATIONS=0

# Rule 1: Hard-coded spacing
echo "Checking for hard-coded spacing..."
if grep -rn "spacing:\s*[0-9]" --include="*.swift" VeloReady/Features 2>/dev/null; then
    echo "❌ Found hard-coded spacing"
    ((VIOLATIONS++))
else
    echo "✅ No hard-coded spacing"
fi

# Rule 2: Hard-coded padding
echo "Checking for hard-coded padding..."
if grep -rn "\.padding([0-9]" --include="*.swift" VeloReady/Features 2>/dev/null; then
    echo "❌ Found hard-coded padding"
    ((VIOLATIONS++))
else
    echo "✅ No hard-coded padding"
fi

# Rule 3: Magic numbers
echo "Checking for magic numbers..."
if grep -rn "CGFloat\s*=\s*[0-9]" --include="*.swift" VeloReady/Features 2>/dev/null | grep -v "duration\|opacity\|0\.[0-9]"; then
    echo "❌ Found magic numbers"
    ((VIOLATIONS++))
else
    echo "✅ No magic numbers"
fi

echo "=========================="
if [ $VIOLATIONS -eq 0 ]; then
    echo "✅ All checks passed!"
    exit 0
else
    echo "❌ Found $VIOLATIONS violation(s)"
    exit 1
fi
```

Make executable:
```bash
chmod +x scripts/lint-check.sh
```

---

## 🎯 **ENFORCEMENT LEVELS**

### **Error (Must Fix)**
- Hard-coded spacing in new code
- Hard-coded padding in new code
- Business logic in views
- Missing ViewModels for cards

### **Warning (Should Fix)**
- Magic numbers in component sizes
- Hard-coded strings
- Missing @MainActor on ViewModels

### **Info (Nice to Fix)**
- Inconsistent color usage
- Missing documentation

---

## 📚 **REFERENCES**

- `SPACING_GUIDELINES.md` - Spacing token usage
- `COMPREHENSIVE_ARCHITECTURE_AUDIT.md` - Architecture standards
- `NON_CARD_COMPONENTS_AUDIT.md` - Component audit results

---

## ✅ **CHECKLIST FOR NEW COMPONENTS**

Before submitting a PR:

- [ ] No hard-coded spacing values
- [ ] No hard-coded padding values
- [ ] No magic numbers (use ComponentSizes)
- [ ] Uses atomic wrappers (ChartCard, CardContainer, etc.)
- [ ] No business logic in view
- [ ] ViewModel has @MainActor
- [ ] No hard-coded strings (use *Content.*)
- [ ] Uses color tokens
- [ ] Build succeeds
- [ ] Linting checks pass

---

**Last Updated:** October 23, 2025  
**Compliance Rate:** 100% (after refactoring)  
**Next Review:** As needed for new components
