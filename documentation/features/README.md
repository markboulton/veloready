# Feature Documentation

Documentation for VeloReady features and capabilities.

## Core Features

### Scoring System

- **[SCORING_METHODOLOGY.md](SCORING_METHODOLOGY.md)** ⭐ **ESSENTIAL**
  - Detailed breakdown of Recovery, Sleep, and Strain scores
  - Data points collected (HRV, RHR, sleep stages, etc.)
  - Calculation formulas and algorithms
  - Research references

### Resilience & Error Handling

- **[CIRCUIT_BREAKER.md](CIRCUIT_BREAKER.md)**
  - Circuit breaker pattern for API calls
  - Failure detection and recovery
  - Prevents cascade failures

- **[CLIENT_SIDE_THROTTLING.md](CLIENT_SIDE_THROTTLING.md)**
  - Request throttling to prevent rate limit errors
  - Per-endpoint rate limits
  - Queue management

- **[EXPONENTIAL_BACKOFF_RETRY.md](EXPONENTIAL_BACKOFF_RETRY.md)**
  - Retry strategy for failed requests
  - Exponential backoff algorithm
  - Max retry limits

- **[TIER_LIMIT_ERROR_HANDLING.md](TIER_LIMIT_ERROR_HANDLING.md)**
  - Free vs Pro tier limits
  - Graceful degradation
  - User-friendly error messages

### Data Storage & Sync

- **[CLOUDKIT_BACKUP_RESTORE.md](CLOUDKIT_BACKUP_RESTORE.md)**
  - CloudKit backup strategy
  - Automatic sync
  - Restore process

## Research & Future Features

### Stress Score (Proposed)

- **[STRESS_COMPARISON_OURA.md](STRESS_COMPARISON_OURA.md)** 🔬 **RESEARCH**
  - Comparison with Oura's cumulative stress feature
  - Research-backed approach
  - Data requirements

- **[STRESS_UI_STRATEGY.md](STRESS_UI_STRATEGY.md)** 🔬 **RESEARCH**
  - UI/UX implications of adding stress metric
  - Metric prioritization analysis
  - Proposes stress as supporting metric, not north star

## Feature Categories

### ✅ Implemented
- Recovery score (HRV, RHR, sleep, training load)
- Sleep score (duration, quality, consistency)
- Strain score (TRIMP-based, Whoop-style)
- AI brief (personalized daily summary)
- Multi-source activity integration (Strava, Intervals.icu, HealthKit)
- CloudKit backup
- Tier-based limits (Free vs Pro)
- Circuit breaker pattern
- Client-side throttling
- Exponential backoff retry

### 🔬 Research Phase
- Cumulative stress score
- Temperature-based illness detection enhancements
- Advanced HRV trend analysis

### 📋 Planned
- Watch app
- Widgets (iOS 17+)
- Android app
- Web dashboard

## Related Documentation

- **Architecture**: See `../architecture/` for technical implementation
- **Implementation**: See `../implementation/` for detailed feature specs
- **Testing**: See `../testing/` for feature testing guides

---

**Last Updated:** November 11, 2025  
**Status:** Current and actively maintained




