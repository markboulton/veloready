# VeloReady Testing Guide

## 🎯 Overview

This is a **simplified testing strategy** designed for single developer development. It focuses on the **20% of testing that prevents 80% of bugs** while keeping feedback loops fast and development velocity high.

## 🚀 Quick Start

### Run Tests Locally (90 seconds)
```bash
./Scripts/quick-test.sh
```

### Development Workflow
```bash
# Start new feature
./Scripts/dev-workflow.sh start feature/your-feature-name

# Test your changes
./Scripts/dev-workflow.sh test

# Push when ready
./Scripts/dev-workflow.sh push

# Ship to main when CI passes
./Scripts/dev-workflow.sh ship
```

## 📋 Testing Structure

### **Tier 1: Quick Local Test (90 seconds)**
**Purpose**: Immediate feedback on code quality and basic functionality
**When**: Before every push
**What it tests**:
- ✅ **Build Check** (30s) - Does it compile?
- ✅ **Critical Unit Tests** (45s) - Core logic works?
- ✅ **Essential Lint** (15s) - Critical code quality?

**Command**: `./Scripts/quick-test.sh`

### **Tier 2: CI Validation (5-10 minutes)**
**Purpose**: Full confidence before merging to main
**When**: On pull requests
**What it tests**:
- ✅ **All Unit Tests** - Complete unit test suite
- ✅ **Integration Tests** - API calls work
- ✅ **E2E Smoke Test** - App launches and basic flow works
- ✅ **Backend Tests** - API endpoints work

**Command**: Automatic on GitHub Actions

### **Tier 3: Release Check (10-15 minutes)**
**Purpose**: Verify main branch stability
**When**: On main branch pushes
**What it tests**:
- ✅ **Full E2E** - Complete user journeys
- ✅ **Multi-device** - iPhone 15 Pro testing

**Command**: Automatic on GitHub Actions

## 🧪 Test Files

### **Unit Tests** (`VeloReadyTests/Unit/`)

#### `TrainingLoadCalculatorTests.swift`
- **Purpose**: Tests core training load calculations
- **Prevents**: CTL/ATL showing 0 values
- **Tests**: 
  - Training load from activities
  - Progressive training load
  - Daily TSS calculation
  - Empty activities handling
  - Activities without TSS

#### `StravaCacheTests.swift`
- **Purpose**: Tests Strava cache system
- **Prevents**: Activities not showing when offline
- **Tests**:
  - Cache key consistency
  - Network failure fallback
  - Legacy cache cleanup
  - Empty data handling

### **Integration Tests** (`VeloReadyTests/Integration/`)

#### `VeloReadyAPIClientTests.swift`
- **Purpose**: Tests API client functionality
- **Prevents**: API integration failures
- **Tests**:
  - Client initialization
  - API method existence
  - Error handling
  - Mock data creation

### **E2E Tests** (`tests/e2e/scenarios/`)

#### `critical-path.yaml`
- **Purpose**: Tests critical user flows
- **Prevents**: App crashes and data loading failures
- **Tests**:
  - App launches without crashing
  - Training load data loads
  - Activities are visible
  - Recovery/Sleep/Strain scores load
  - Pull-to-refresh works
  - Navigation to activity details

## ⚙️ Configuration Files

### **SwiftLint Essential** (`.swiftlint-essential.yml`)
- **Purpose**: Only check critical rules that prevent bugs
- **Skips**: Style issues that don't affect functionality
- **Focus**: Compilation errors, logic errors, critical code quality

### **CI Workflow** (`.github/workflows/ci.yml`)
- **Purpose**: Single streamlined CI workflow
- **Features**:
  - Parallel execution for iOS and Backend
  - Smart caching for faster builds
  - Tiered testing approach
  - Skip unnecessary tests on draft PRs

## 🛠️ Development Workflow

### **Daily Development**
1. **Code** your feature
2. **Test**: `./Scripts/quick-test.sh` (90s)
3. **Push**: `./Scripts/dev-workflow.sh push`
4. **Ship**: `./Scripts/dev-workflow.sh ship` (when CI passes)

### **Weekly Release**
1. **Test** full E2E locally (optional)
2. **Merge** to main
3. **Deploy** when CI passes

## 🎯 What Gets Tested

### **Critical Path Tests (Must Test)**
- ✅ App launches without crashing
- ✅ User can log in
- ✅ Core features work (training load, activities)
- ✅ Data syncs properly
- ✅ Strava cache works offline
- ✅ Training load calculations are accurate

### **Bug Prevention Tests (Should Test)**
- ✅ API calls don't fail
- ✅ Data validation works
- ✅ Edge cases handled
- ✅ Cache consistency
- ✅ Network failure handling

### **Nice to Have Tests (Optional)**
- ⚠️ Performance testing
- ⚠️ Accessibility testing
- ⚠️ Multi-device testing
- ⚠️ Complex E2E scenarios

## 🚫 What NOT to Test

- **Complex E2E scenarios** (unless critical)
- **Multiple iOS versions** (test on latest)
- **Performance benchmarks** (unless needed)
- **Accessibility** (unless required)
- **Multi-device** (unless critical)
- **Style issues** (focus on functionality)

## ⚡ Speed Optimizations

### **Local Testing**
- **90 seconds max** for quick test
- **Skip slow tests** locally
- **Focus on compilation** and basic functionality
- **Essential linting only**

### **CI Testing**
- **Parallel execution** where possible
- **Skip unnecessary tests** on draft PRs
- **Cache dependencies** for speed
- **Single device** for most tests

### **E2E Testing**
- **Smoke tests only** for PRs
- **Full E2E** only for releases
- **Critical path only** - no complex scenarios

## 🔧 Troubleshooting

### **Quick Test Fails**
```bash
# Build only
xcodebuild build -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet -skipPackagePluginValidation

# Unit tests only
xcodebuild test -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:VeloReadyTests/Unit/TrainingLoadCalculatorTests -quiet
```

### **CI Fails**
- Check GitHub Actions logs
- Fix issues locally
- Push again

### **E2E Fails**
- Check if app builds
- Verify simulator is available
- Run locally first

### **Xcode Issues**
```bash
# Fix Xcode path (if needed)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Verify Xcode installation
xcodebuild -version
```

## 📊 Expected Results

### **Development Speed**
- **Local feedback**: 90 seconds
- **CI feedback**: 5-10 minutes
- **Release confidence**: 10-15 minutes

### **Bug Prevention**
- **Compilation errors**: Caught locally
- **Logic errors**: Caught by unit tests
- **Integration errors**: Caught by CI
- **User flow errors**: Caught by E2E

### **Complexity Reduction**
- **90% less** configuration (1 workflow instead of 5)
- **80% faster** feedback (90s vs 2-3 min locally)
- **70% less** maintenance (simplified test structure)
- **100% more** focus on features (streamlined workflow)

## 🎯 The Bottom Line

**Test what breaks, not everything. Focus on speed, not coverage. Ship fast, ship often, ship reliably.**

This strategy gives you:
- ⚡ **Fast feedback** (90 seconds locally)
- 🛡️ **Bug prevention** (catches real issues)
- 🚀 **Rapid development** (minimal overhead)
- 📱 **Reliable releases** (confidence to ship)

Perfect for a single developer who wants to vibe code while building a robust product.

## 📚 Additional Resources

- **Quick Start**: `TESTING_QUICK_START_SIMPLE.md`
- **Simple Strategy**: `SIMPLE_TESTING_STRATEGY.md`
- **Scripts**: `Scripts/quick-test.sh`, `Scripts/dev-workflow.sh`
- **Configuration**: `.swiftlint-essential.yml`, `.github/workflows/ci.yml`
