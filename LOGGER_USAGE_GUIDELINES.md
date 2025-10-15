# Logger Usage Guidelines
**Critical Rules for Using Logger in SwiftUI**

---

## ⚠️ **Critical Rule: Never Log During View Body Computation**

SwiftUI views must be **pure computations** during body evaluation. Logging is a **side effect** and violates this rule.

### ❌ **WRONG: Logging in View Body**

```swift
struct MyView: View {
    var body: some View {
        // ❌ DON'T DO THIS - Will cause crashes or undefined behavior
        Logger.debug("Rendering view")
        
        VStack {
            Text("Hello")
        }
    }
}
```

### ❌ **WRONG: Logging in Computed Properties Used by Views**

```swift
struct MyView: View {
    private func hasData() -> Bool {
        // ❌ DON'T DO THIS - Called during view rendering
        Logger.data("Checking data")
        return data.count > 0
    }
    
    var body: some View {
        if hasData() {  // ← This calls the function during rendering
            Text("Has data")
        }
    }
}
```

### ❌ **WRONG: Logging in Properties Accessed by View**

```swift
struct MyView: View {
    var formattedDate: String {
        // ❌ DON'T DO THIS - Computed during view rendering
        Logger.debug("Formatting date")
        return date.formatted()
    }
    
    var body: some View {
        Text(formattedDate)  // ← Accesses property during rendering
    }
}
```

---

## ✅ **CORRECT: Where to Use Logger in Views**

### ✅ **In Lifecycle Modifiers**

```swift
struct MyView: View {
    var body: some View {
        VStack {
            Text("Hello")
        }
        .onAppear {
            // ✅ CORRECT - Lifecycle method, not during rendering
            Logger.debug("View appeared")
        }
        .task {
            // ✅ CORRECT - Task runs after view appears
            Logger.debug("Starting data fetch")
            await fetchData()
        }
        .onChange(of: someValue) { old, new in
            // ✅ CORRECT - Callback, not during rendering
            Logger.debug("Value changed from \(old) to \(new)")
        }
    }
}
```

### ✅ **In Button Actions & Callbacks**

```swift
struct MyView: View {
    var body: some View {
        Button("Save") {
            // ✅ CORRECT - User action callback
            Logger.debug("Save button tapped")
            save()
        }
    }
}
```

### ✅ **In ViewModels & Services**

```swift
@MainActor
class MyViewModel: ObservableObject {
    func loadData() async {
        // ✅ CORRECT - Service method, not view rendering
        Logger.debug("Loading data")
        let data = await api.fetch()
        Logger.data("Loaded \(data.count) items")
    }
}
```

---

## 🔍 **Debug Print Pattern (Safe Exception)**

The `let _ = print()` pattern is **safe** because it's suppressed:

### ✅ **Suppressed Debug Prints (OK)**

```swift
struct MyView: View {
    var body: some View {
        // ✅ SAFE - Suppressed, used for debugging only
        let _ = print("📊 Rendering with \(items.count) items")
        
        return List(items) { item in
            Text(item.name)
        }
    }
}
```

**Why this is safe:**
- The `let _ = ` suppresses the print's result
- Standard SwiftUI debugging pattern
- Does NOT interfere with view rendering
- Can be left in code for debugging

**However**, still prefer using `Logger` in `onAppear`:

```swift
// ✅ BETTER - Use Logger in lifecycle
struct MyView: View {
    var body: some View {
        List(items) { item in
            Text(item.name)
        }
        .onAppear {
            Logger.debug("Rendering with \(items.count) items")
        }
    }
}
```

---

## 📋 **Quick Reference**

| Location | Logger Allowed? | Alternative |
|----------|----------------|-------------|
| `var body: some View { }` | ❌ NO | Use `onAppear { }` |
| Computed properties used in body | ❌ NO | Log in caller, not property |
| `func` called from body | ❌ NO | Log before/after call |
| `.onAppear { }` | ✅ YES | Perfect place |
| `.task { }` | ✅ YES | Perfect place |
| `.onChange { }` | ✅ YES | Perfect place |
| Button actions | ✅ YES | Perfect place |
| ViewModels | ✅ YES | Perfect place |
| Services | ✅ YES | Perfect place |
| `let _ = print()` | ⚠️ OK | Suppressed debug pattern |

---

## 🐛 **Common Crash Scenarios**

### Scenario 1: Chart Rendering

```swift
// ❌ CRASH - Logger in helper called during rendering
private func hasData() -> Bool {
    Logger.data("Checking data")  // ← CRASHES
    return !samples.isEmpty
}

var body: some View {
    if hasData() {  // ← Called during rendering
        ChartView()
    }
}

// ✅ FIX - Remove Logger, use onAppear if needed
private func hasData() -> Bool {
    return !samples.isEmpty  // ← Pure computation
}

var body: some View {
    if hasData() {
        ChartView()
            .onAppear {
                Logger.debug("Chart shown with \(samples.count) samples")
            }
    }
}
```

### Scenario 2: List Performance

```swift
// ❌ PERFORMANCE - Logger called for every item
struct ItemRow: View {
    let item: Item
    
    var body: some View {
        let _ = Logger.debug("Rendering \(item.name)")  // ← Bad performance
        return Text(item.name)
    }
}

// ✅ FIX - Log once for the list
struct ItemList: View {
    let items: [Item]
    
    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
        .onAppear {
            Logger.debug("List appeared with \(items.count) items")
        }
    }
}
```

---

## 🎯 **Best Practices**

1. **Log state changes**, not view renders
2. **Log user actions**, not UI updates
3. **Log data operations**, not computations
4. **Use lifecycle methods** for view-related logging
5. **Keep view body pure** - no side effects

### Good Logging Pattern

```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    func refresh() async {
        Logger.debug("Starting refresh")
        
        do {
            items = try await api.fetchItems()
            Logger.data("Loaded \(items.count) items")
        } catch {
            Logger.error("Refresh failed", error: error)
        }
    }
}

struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task {
            await viewModel.refresh()
        }
    }
}
```

---

## 📝 **Summary**

**Golden Rule:** Logger is for **actions and events**, not **computations and rendering**.

**Safe Places:**
- ✅ `.onAppear`, `.task`, `.onChange`
- ✅ Button actions and callbacks
- ✅ ViewModels and services

**Unsafe Places:**
- ❌ `var body: some View`
- ❌ Computed properties used by body
- ❌ Functions called during rendering

**Remember:** If SwiftUI is computing your view, don't log. If your code is responding to an event, logging is fine.
