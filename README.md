# VeloReady

A comprehensive cycling performance and recovery tracking app for iOS.

## 🎉 Phase 1 Complete - VeloReadyCore Extraction (Nov 2025)

Successfully extracted all core calculation logic to `VeloReadyCore` Swift Package:
- **1,056 lines** of pure calculation logic extracted
- **82 comprehensive tests** (all passing in <2 seconds)
- **39x faster testing** (2s vs 78s with iOS simulator)
- **Zero iOS dependencies** - reusable in backend, ML, widgets, watch
- **Single source of truth** - no duplicate calculation logic

See [PHASE1_FINAL_COMPLETE.md](PHASE1_FINAL_COMPLETE.md) for full details.

## 🚴 Features

- **Multi-Source Data**: Integrates with Strava and Intervals.icu
- **Training Load**: CTL/ATL/TSB tracking with adaptive zones
- **Recovery Metrics**: HRV, RHR, sleep analysis
- **AI Insights**: Personalized training recommendations
- **Activity Analysis**: Power curves, zone distribution, detailed metrics

## 🏗️ Architecture

### Backend
- Netlify Functions for API proxying
- Supabase for data storage
- Redis for rate limiting
- Custom domain: `api.veloready.app`

### iOS App
- SwiftUI
- Core Data with CloudKit sync
- HealthKit integration
- Adaptive FTP and HR zones

## 📚 Documentation

**Start here**: [`documentation/INDEX.md`](documentation/INDEX.md) - Complete documentation index

All project documentation is organized in the [`documentation/`](documentation/) folder:
- **implementation/** - Architecture, phases, and features (48 docs)
- **testing/** - Testing strategies and guides (10 docs)
- **fixes/** - Bug fixes and optimizations (21 docs)
- **ui-ux/** - Design system and components (20 docs)
- **sessions/** - Progress tracking and summaries (14 docs)
- **guides/** - Development references (8 docs)

See [`documentation/ORGANIZATION_SUMMARY.md`](documentation/ORGANIZATION_SUMMARY.md) for the complete structure.

## 🚀 Quick Start

### Prerequisites
- Xcode 15+
- iOS 17+
- Strava and/or Intervals.icu account

### Setup
1. Open `VeloReady.xcodeproj`
2. Configure signing & capabilities
3. Add your API keys to environment
4. Build and run

## 🧪 Testing

See `PHASE_1_2_TESTING_CHECKLIST.md` for comprehensive testing guide.

## 📱 Current Status

**Phase 1: API Centralization** - ✅ Complete
- Backend deployed to `api.veloready.app`
- Clean URL structure
- 24-hour edge caching
- Multi-source support (Strava + Intervals.icu)

**Phase 2: Cache Unification** - ⏳ In Progress
- UnifiedCacheManager implemented
- Request deduplication active
- Service migrations ongoing

## 🔧 Development

```bash
# Backend (Netlify)
cd ../veloready-website
netlify dev

# iOS
open VeloReady.xcodeproj
```

## 📄 License

Proprietary - All rights reserved
