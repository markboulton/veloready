# VeloReady

**The smart cycling analytics app for iOS**

VeloReady helps cyclists optimize their training with advanced analytics, recovery tracking, and performance insights powered by Apple Health, Strava, and Intervals.icu.

---

## 🚴‍♂️ Features

### Core Features
- **Daily Recovery Score** - Science-backed recovery analysis using HRV, RHR, and sleep
- **Sleep Tracking** - Comprehensive sleep quality scoring and recommendations
- **Training Load** - Smart load management on a 0-18 scale with decimal precision
- **Activity Analytics** - Detailed ride analysis with power zones, IF, and TSS
- **Trends Dashboard** - Track your fitness progression over time

### Integrations
- **Apple Health** - Primary data source for health metrics
- **Strava** - Activity sync and social features
- **Intervals.icu** - Advanced training analytics and FTP tracking

### Advanced Features
- **Adaptive FTP** - Dynamic FTP estimation based on your rides
- **Power Zones** - Personalized training zones from multiple sources
- **AI Ride Summaries** - Intelligent ride analysis and insights
- **Wellness Detection** - Alcohol impact tracking and health pattern recognition
- **HealthKit-Only Mode** - Full functionality without external integrations

---

## 🏗️ Architecture

### Tech Stack
- **Language:** Swift 5.9
- **UI Framework:** SwiftUI
- **Minimum iOS:** 17.0
- **Data Storage:** Core Data + UserDefaults
- **Authentication:** OAuth 2.0 (ASWebAuthenticationSession)

### Project Structure
```
VeloReady/
├── App/                    # App entry point
├── Core/                   # Core services and models
│   ├── Models/            # Data models
│   ├── Services/          # Business logic services
│   ├── Networking/        # API clients
│   └── Data/              # Core Data stack
├── Features/              # Feature modules
│   ├── Today/            # Today dashboard
│   ├── Activities/       # Activity list and details
│   ├── Trends/           # Trends and analytics
│   ├── Onboarding/       # User onboarding flow
│   └── Settings/         # App settings
├── Design/               # Design system
│   ├── Tokens/          # Design tokens (colors, typography)
│   └── Components/      # Reusable UI components
├── Shared/              # Shared utilities
└── Resources/           # Assets and localization
```

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- Apple Developer account (for HealthKit entitlements)
- Strava Developer account (optional, for Strava integration)
- Intervals.icu account (optional, for Intervals integration)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/veloready.git
   cd veloready
   ```

2. **Open in Xcode**
   ```bash
   open VeloReady.xcodeproj
   ```

3. **Configure signing**
   - Select VeloReady target
   - Signing & Capabilities → Team: (select your team)
   - Bundle Identifier: `com.veloready.app`

4. **Add HealthKit entitlement**
   - Signing & Capabilities → + Capability → HealthKit

5. **Build and run**
   - ⌘ + R to run on simulator or device

### Configuration

#### OAuth Credentials

**Strava:**
1. Create app at https://www.strava.com/settings/api
2. Add callback URLs:
   - `veloready://auth/strava/callback`
   - `https://veloready.app/auth/strava/callback`
3. Update `StravaAuthConfig.swift` with your credentials

**Intervals.icu:**
1. Create app at https://intervals.icu/settings/api
2. Add redirect URIs:
   - `veloready://auth/intervals/callback`
   - `https://veloready.app/auth/intervals/callback`
3. Update `IntervalsOAuthManager.swift` with your credentials

#### Environment Variables

Create a `.xcconfig` file (not tracked in Git):
```
STRAVA_CLIENT_ID = your_client_id
STRAVA_CLIENT_SECRET = your_client_secret
INTERVALS_CLIENT_ID = your_client_id
INTERVALS_CLIENT_SECRET = your_client_secret
```

---

## 🧪 Testing

### Unit Tests
```bash
⌘ + U
```

### OAuth Testing
**Important:** OAuth and Universal Links must be tested on a physical device, not simulator!

1. Build and install on iPhone
2. Test Strava OAuth flow
3. Test Intervals.icu OAuth flow
4. Verify Universal Links work

### Test Accounts
See `TESTING_GUIDE.md` for test account credentials and testing procedures.

---

## 📦 Dependencies

### Apple Frameworks
- SwiftUI - UI framework
- HealthKit - Health data access
- CoreData - Local data persistence
- BackgroundTasks - Background refresh
- AuthenticationServices - OAuth flows

### External APIs
- Strava API v3
- Intervals.icu API v1

No external Swift packages required - pure Apple frameworks!

---

## 🏛️ Design System

VeloReady uses a comprehensive design system with semantic tokens:

- **Colors:** `ColorScale`, `ColorPalette`
- **Typography:** System fonts with semantic sizes
- **Components:** Reusable SwiftUI components
- **Layouts:** Consistent spacing and sizing

See `Design/Tokens/` for complete design token documentation.

---

## 📱 Features Deep Dive

### Recovery Score
**Algorithm:** Whoop-inspired recovery calculation
- HRV (30%) - Heart rate variability
- RHR (20%) - Resting heart rate  
- Sleep (30%) - Sleep quality and duration
- Respiratory Rate (10%)
- Training Load (10%)

**Special Features:**
- Alcohol detection via HRV patterns
- Sleep quality impact analysis
- Recovery trends over time

### Training Load
**New 0-18 Scale:**
- 0-4.4: Light activity day
- 4.5-8.9: Moderate training
- 9.0-14.3: Hard training day
- 14.4-18.0: Extreme load

**Calculation:**
- TRIMP-based (Training Impulse)
- Power and HR data integration
- Non-exercise activity included

### Adaptive FTP
**Smart FTP Estimation:**
- Analyzes threshold efforts
- Uses 20-min and 60-min power
- Machine learning-inspired detection
- Updates based on performance trends

---

## 🔒 Privacy & Security

### Data Storage
- **Local First:** All data stored locally on device
- **Encrypted:** HealthKit data encrypted by iOS
- **No Tracking:** Zero third-party analytics
- **User Control:** Users can delete all data anytime

### OAuth Security
- State parameter validation (CSRF protection)
- Secure token storage in Keychain
- Token refresh with exponential backoff
- No credentials stored in code

### HealthKit Permissions
- Granular permission requests
- Read-only by default
- Users can revoke anytime
- Transparent about data usage

---

## 🚢 Deployment

### TestFlight Beta
1. Archive the app (⌘ + B with Archive scheme)
2. Upload to App Store Connect
3. Add beta testers
4. Distribute for testing

### App Store Submission
1. Update version and build number
2. Prepare screenshots and metadata
3. Submit for review
4. Monitor review status

### Infrastructure
- **Domain:** veloready.app (Netlify)
- **OAuth Callbacks:** Serverless functions
- **Universal Links:** apple-app-site-association
- **CDN:** Netlify CDN for fast global access

---

## 📚 Documentation

- `/SETUP_INSTRUCTIONS.md` - Complete setup guide
- `/documentation/` - Detailed feature docs
- `/TESTING_GUIDE.md` - Testing procedures
- `/DESIGN_TOKENS_REFERENCE.md` - Design system reference

---

## 🤝 Contributing

This is a personal project, but feedback and bug reports are welcome!

### Reporting Bugs
- Use GitHub Issues
- Include iOS version, device model, and repro steps
- Screenshots are helpful

### Feature Requests
- Open a discussion on GitHub
- Explain the use case and value

---

## 📄 License

Copyright © 2025 VeloReady

All rights reserved. This is proprietary software.

---

## 🙏 Acknowledgments

### Inspiration
- **Whoop** - Recovery and strain algorithms
- **TrainingPeaks** - TSS and training load concepts
- **Intervals.icu** - Advanced cycling analytics

### Data Sources
- Apple HealthKit
- Strava
- Intervals.icu

### Technologies
- SwiftUI - Apple
- HealthKit - Apple
- Core Data - Apple

---

## 📞 Support

- **Email:** support@veloready.app
- **Website:** https://veloready.app
- **Issues:** GitHub Issues

---

## 🗺️ Roadmap

### Version 1.0 (Current)
- ✅ Recovery, Sleep, Load scores
- ✅ Strava & Intervals.icu integration
- ✅ HealthKit-only mode
- ✅ Activity analytics with zones
- ✅ Trends dashboard

### Version 1.1 (Planned)
- [ ] Apple Watch app
- [ ] Widgets for Lock Screen
- [ ] Live Activities during rides
- [ ] More sports (running, swimming)
- [ ] Training plan suggestions

### Version 2.0 (Future)
- [ ] Social features (compare with friends)
- [ ] Coach mode (for trainers)
- [ ] Advanced analytics (CTL, ATL, TSB charts)
- [ ] Race day predictions
- [ ] Integration with more platforms

---

## 🎯 Mission

**Make data-driven training accessible to every cyclist.**

VeloReady brings professional-grade analytics to everyday cyclists, helping you train smarter, recover better, and ride faster.

---

**Built with ❤️ for the cycling community** 🚴‍♂️

---

**Version:** 1.0.0  
**Last Updated:** 2025-10-12  
**Min iOS:** 17.0
