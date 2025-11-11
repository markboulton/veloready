# Architecture Documentation

Current architecture documentation for VeloReady.

## Current Architecture (November 2025)

### Core Architecture

- **[ARCHITECTURE_FIX_HEALTHKIT_INIT.md](ARCHITECTURE_FIX_HEALTHKIT_INIT.md)** ⭐ **CRITICAL**
  - Architectural fix for HealthKit initialization race condition
  - Explains the state-driven rendering pattern
  - **Must-read** for understanding app startup sequence

- **[RESILIENCE_ANALYSIS.md](RESILIENCE_ANALYSIS.md)** ⭐ **CRITICAL**
  - Comprehensive analysis of architectural resilience
  - Explains why race conditions were eliminated by design
  - Verification of edge cases and guarantees

- **[TECHNICAL_DEBT_ANALYSIS.md](TECHNICAL_DEBT_ANALYSIS.md)**
  - Recent code health analysis
  - Technical debt items identified and fixed
  - Cache key normalization, duplicate code removal

### Today View Architecture

- **[TODAY_CODE_HEALTH_SUMMARY.md](TODAY_CODE_HEALTH_SUMMARY.md)**
  - High-level summary of Today view refactoring
  - Code health metrics
  - Testing results

### Backend Architecture

- **[SUPABASE_AUTH_ROBUSTNESS_ANALYSIS.md](SUPABASE_AUTH_ROBUSTNESS_ANALYSIS.md)**
  - Supabase authentication architecture
  - Proactive token refresh
  - Session management

- **[SUPABASE_AUTH_ROBUSTNESS_COMPLETE.md](SUPABASE_AUTH_ROBUSTNESS_COMPLETE.md)**
  - Implementation summary
  - Error handling patterns
  - Testing verification

## Related Documentation

- **Implementation Details**: See `../implementation/` for feature architecture
- **Historical Context**: See `../archive/refactoring/` for evolution of architecture
- **Design System**: See `../ui-ux/` for UI architecture

## Key Architectural Patterns

### 1. **Coordinator Pattern**
- `TodayCoordinator` - Orchestrates Today view lifecycle
- `ScoresCoordinator` - Manages score calculation and state
- `ActivitiesCoordinator` - Coordinates activity fetching

### 2. **State-Driven Rendering**
- UI rendering blocked until initialization completes
- Eliminates race conditions by design
- Observable state through `@Published` properties

### 3. **Dependency Injection**
- `ServiceContainer` provides centralized service management
- Lazy initialization prevents circular dependencies
- Testable architecture

### 4. **Actor Isolation**
- `@MainActor` for UI-bound operations
- Background actors for heavy computation
- `Sendable` conformance for cross-actor communication

## Architecture Diagrams

### App Startup Sequence (Post-Fix)

```
RootView (black screen)
  ↓
  Wait for HealthKit auth check (0.5s)
  ↓
  isInitialized = true
  ↓
  Render MainTabView
  ↓
  Show branding animation (3s)
  ↓
  Render TodayView
  ↓
  TodayCoordinator.loadInitial()
  ↓
  Calculate scores (guaranteed correct auth status)
```

### Coordinator Hierarchy

```
ServiceContainer (singleton)
  ├── TodayCoordinator (lifecycle orchestration)
  │   ├── ScoresCoordinator (score management)
  │   └── ActivitiesCoordinator (activity fetching)
  ├── HealthKitManager
  │   └── HealthKitAuthorizationCoordinator
  └── LoadingStateManager (shared state)
```

---

**Last Updated:** November 11, 2025  
**Status:** Current and actively maintained


