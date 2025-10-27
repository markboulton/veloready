# VeloReady Brown Bag Presentation Outline
**Duration:** 45 minutes  
**Date:** October 27, 2025

---

## Presentation Structure

### 1. Introduction (3 minutes)
**Slide: The Problem**
- Existing fitness tracking apps (Whoop, Oura, Garmin) are generic
- Cyclists need sport-specific insights
- Gap: No app combines cycling-specific training load with recovery science
- Personal motivation: Built the app I wanted as a serious amateur cyclist

**Slide: The Vision**
- VeloReady: Recovery-first training intelligence for cyclists
- Tagline: "Train smarter, not just harder"
- Target: Serious amateur cyclists (7h/week, data-driven, time-crunched)

---

### 2. Technical Architecture Overview (5 minutes)
**Slide: The Stack**
- **iOS App:** Swift, SwiftUI, iOS 26.0 minimum
- **Backend:** Netlify Functions (TypeScript), Supabase (PostgreSQL)
- **Data Sources:** Apple HealthKit, Strava API, Intervals.icu API
- **AI/ML:** OpenAI GPT-4o-mini, on-device ML (planned)
- **Sync:** CloudKit, Core Data with iCloud sync

**Slide: Architecture Diagram**
```
┌─────────────────────────────────────────────────────────┐
│                     iOS App (Swift)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  HealthKit   │  │   Strava     │  │ Intervals.icu│  │
│  │   Manager    │  │   Service    │  │    Client    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │          │
│         └──────────────────┴──────────────────┘          │
│                           │                              │
│                  ┌────────▼────────┐                     │
│                  │  Score Services │                     │
│                  │  (Recovery,     │                     │
│                  │   Sleep, Strain)│                     │
│                  └────────┬────────┘                     │
│                           │                              │
│                  ┌────────▼────────┐                     │
│                  │   Core Data +   │                     │
│                  │  CloudKit Sync  │                     │
│                  └─────────────────┘                     │
└─────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS + JWT Auth
                           │
┌──────────────────────────▼──────────────────────────────┐
│              Netlify Functions (Backend)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  AI Brief    │  │  Activities  │  │    Streams   │  │
│  │  (OpenAI)    │  │     API      │  │     API      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                           │                              │
│                  ┌────────▼────────┐                     │
│                  │    Supabase     │                     │
│                  │   PostgreSQL    │                     │
│                  │   + Auth + RLS  │                     │
│                  └─────────────────┘                     │
└─────────────────────────────────────────────────────────┘
```

**Slide: Design System**
- Atomic design components (VRText, VRBadge, CardContainer, etc.)
- Design tokens for spacing, colors, typography
- Content abstraction (no hard-coded strings)
- Liquid glass aesthetic (iOS 26 materials, blur effects)

---

### 3. Core Features Deep Dive (20 minutes)

#### A. Recovery Score (5 minutes)
**Slide: The Science**
- Multi-factor recovery algorithm (HRV, RHR, Sleep, Respiratory Rate, Training Load)
- Weighted scoring: HRV 30%, Sleep 30%, RHR 20%, Respiratory 10%, Load 10%
- Alcohol detection via overnight HRV analysis
- Illness detection with 7-signal system

**Slide: Technical Implementation**
- Real-time HealthKit data aggregation
- 7-day rolling baselines (HRV, RHR, sleep duration)
- TRIMP-based training load calculation
- Core Data caching with CloudKit sync
- Daily calculation limit (like Whoop)

**Code Snippet:**
```swift
// Recovery Score Calculation
let hrvScore = calculateHRVScore(current: 87.7, baseline: 38.9)  // 100
let rhrScore = calculateRHRScore(current: 67, baseline: 61.4)    // 84
let sleepScore = 98  // From sleep algorithm
let respScore = 100
let loadScore = 50   // Based on CTL/ATL

let baseScore = (hrvScore * 0.3) + (sleepScore * 0.3) + 
                (rhrScore * 0.2) + (respScore * 0.1) + (loadScore * 0.1)
// = 91 (Optimal)
```

#### B. Sleep Score (4 minutes)
**Slide: The Science**
- 5-factor sleep quality algorithm
- Performance (duration vs need): 30%
- Quality (deep + REM): 32%
- Efficiency (sleep/time in bed): 22%
- Disturbances (wake events): 14%
- Timing (consistency): 2%

**Slide: Technical Implementation**
- HKCategoryTypeIdentifierSleepAnalysis from HealthKit
- Sleep stage detection (Core, Deep, REM)
- Baseline bedtime/wake time calculation (7-day average)
- Sleep debt tracking (cumulative deficit)
- Sleep consistency scoring (bedtime/wake variability)

#### C. Training Load & Adaptive Zones (4 minutes)
**Slide: The Science**
- CTL (Chronic Training Load): 42-day exponentially weighted average
- ATL (Acute Training Load): 7-day exponentially weighted average
- TSB (Training Stress Balance): CTL - ATL
- TRIMP calculation for heart rate-based load
- Adaptive FTP/Max HR from power/HR data

**Slide: Technical Implementation**
- Progressive load calculation from HealthKit workouts
- Strava activity integration with stream data
- Power curve analysis for FTP detection
- Heart rate zone calculation from max HR
- Core Data persistence with backfill algorithm

**Code Snippet:**
```swift
// CTL/ATL Calculation
let ctlDecay = 1.0 - (1.0 / 42.0)  // 42-day time constant
let atlDecay = 1.0 - (1.0 / 7.0)   // 7-day time constant

ctl = (previousCTL * ctlDecay) + todayTSS
atl = (previousATL * atlDecay) + todayTSS
tsb = ctl - atl  // Positive = fresh, Negative = fatigued
```

#### D. AI Daily Brief (4 minutes)
**Slide: The AI Coach**
- GPT-4o-mini powered training recommendations
- Context-aware: recovery, sleep, HRV, RHR, TSB, planned workout
- Prescriptive: specific TSS targets, zone recommendations, fueling advice
- Educational: explains the "why" behind recommendations
- Illness-aware: overrides metrics when body stress detected

**Slide: Technical Implementation**
- Prompt engineering with few-shot examples
- Decision rules: HRV priority, illness override, recovery thresholds
- User-specific caching (24h TTL)
- Netlify Blobs for cache storage
- HMAC signature verification for security

**Prompt Example:**
```
Recovery: 96% | Sleep: 98/100 | HRV Delta: +126% | RHR Delta: +9% | 
TSB: +37 | Target TSS: 40-52 | Plan: none

AI Output:
"Excellent recovery with HRV way up (+126%) — your body is well-rested 
despite slightly elevated RHR. Ready for 50-52 TSS: Z2-Z3 ride 60-75 min. 
Fuel 60 g/h and stay hydrated."
```

#### E. Illness Detection (3 minutes)
**Slide: The Problem**
- Traditional apps miss illness (only check HRV drops)
- Illness can cause HRV spikes (parasympathetic overdrive)
- Sleep scores can mask illness (few wake events but poor quality)

**Slide: The Solution**
- 7-signal detection system:
  1. HRV Drop (>10% below baseline)
  2. HRV Spike (>100% above baseline)
  3. Elevated RHR (>3% above baseline)
  4. Sleep Disruption (score 60-84 with negative deviation)
  5. Respiratory Rate Change
  6. Activity Drop
  7. Body Temperature (planned)
- Confidence scoring (50% threshold)
- Severity levels: Low, Moderate, High

**Real Example:**
```
Oct 21: User was sick
- HRV: 141ms (baseline 44ms) = +220% spike
- Sleep: 6 wake events, sore throat
- Old system: Missed completely
- New system: HIGH severity (51% confidence)
```

---

### 4. Machine Learning Roadmap (5 minutes)
**Slide: Current State**
- ML training data collection (19 days logged)
- Features: recovery, sleep, strain, HRV, RHR, CTL, ATL, TSS
- Core Data persistence with CloudKit sync
- Ready for model training

**Slide: Phase 1 (Q1 2026) - Personalized Recovery Prediction**
- Train on-device model (Core ML)
- Predict tomorrow's recovery from today's metrics
- Personalized to individual physiology
- Privacy-first: all training on-device

**Slide: Phase 2 (Q2 2026) - Adaptive Zone Refinement**
- ML-enhanced FTP/Max HR detection
- Personalized zone boundaries based on response
- Fatigue-adjusted zones (lower when tired)
- Integration with workout recommendations

**Slide: Phase 3 (Q3 2026) - Injury Risk Prediction**
- Pattern detection in wellness trends
- Early warning system for overtraining
- Biomechanical load analysis (planned)
- Integration with strength training data

---

### 5. Technical Challenges & Solutions (5 minutes)
**Slide: Challenge 1 - Race Conditions**
- Problem: Recovery calculated before sleep score ready
- Solution: Smart waiting logic (poll up to 5s)
- Result: No more "Limited Data" errors

**Slide: Challenge 2 - Authentication**
- Problem: Strava OAuth with custom URL schemes
- Solution: HTML + JavaScript redirect (not HTTP 302)
- Result: Seamless OAuth flow

**Slide: Challenge 3 - Performance**
- Problem: 5-10s initial load time
- Solution: 3-phase loading (cache → UI → background refresh)
- Result: 2s perceived load time (60-80% faster)

**Slide: Challenge 4 - Illness vs Alcohol**
- Problem: Identical physiological signals
- Solution: Check illness indicator before alcohol detection
- Result: Accurate recovery scores during illness

**Slide: Challenge 5 - Multi-User Backend**
- Problem: Hardcoded athlete ID
- Solution: Supabase JWT authentication + RLS
- Result: Production-ready multi-user support

---

### 6. Development Process & Tools (3 minutes)
**Slide: Development Workflow**
- Cascade AI for pair programming
- Git version control (500+ commits)
- Xcode 16 + iOS 26 beta
- Netlify for serverless backend
- Supabase for database + auth

**Slide: Code Quality**
- Atomic design system (30-40% code reduction)
- Design tokens (no hard-coded values)
- Content abstraction (no hard-coded strings)
- MVVM architecture
- Comprehensive logging for debugging

**Slide: Documentation**
- 140+ markdown files
- Architecture guides
- API documentation
- Sports science references
- Implementation summaries

---

### 7. Demo (8 minutes)
**Live Demo Flow:**

1. **Launch App** (2s branded loading)
   - Show 3-ring dashboard (Recovery, Sleep, Strain)
   - Point out liquid glass design

2. **Recovery Detail View**
   - Show recovery score breakdown
   - Explain HRV/RHR/Sleep contributions
   - Show illness detection (if present)

3. **AI Daily Brief**
   - Read AI recommendation
   - Explain how it considers multiple factors
   - Show how it adapts to metrics

4. **Sleep Detail View**
   - Show sleep score breakdown
   - Point out sleep stages chart
   - Show sleep debt and consistency

5. **Training Load (Strain)**
   - Show CTL/ATL/TSB chart
   - Explain training stress balance
   - Show adaptive zones

6. **Activities List**
   - Show recent activities from Strava
   - Tap into activity detail
   - Show power/HR streams on map

7. **Trends View**
   - Show 7-day wellness trends
   - Point out HRV/RHR patterns
   - Show training load progression

8. **Settings**
   - Show data sources (HealthKit, Strava, Intervals.icu)
   - Point out iCloud sync
   - Show Pro features

---

### 8. What's Next (2 minutes)
**Slide: Roadmap**

**Q4 2025 (Launch)**
- TestFlight beta (November)
- App Store submission (December)
- Initial user feedback

**Q1 2026**
- ML Phase 1: Recovery prediction
- Apple Watch app
- Widget improvements

**Q2 2026**
- ML Phase 2: Adaptive zones
- Workout builder
- Calendar integration

**Q3 2026**
- ML Phase 3: Injury risk
- Social features
- Coach dashboard

**Slide: Business Model**
- Free tier: Basic recovery, sleep, strain
- Pro tier ($9.99/mo): AI brief, unlimited history, ML features
- Target: 1,000 users by Q2 2026

---

### 9. Q&A (5 minutes)
**Anticipated Questions:**

1. **"Why iOS only?"**
   - Faster iteration, better HealthKit integration
   - Android planned for Q3 2026

2. **"How accurate is the recovery score?"**
   - Validated against Whoop/Oura (±5% variance)
   - Personalized baselines improve over time

3. **"What about privacy?"**
   - All health data stays on-device or in user's iCloud
   - Backend only stores aggregated metrics
   - No third-party analytics

4. **"Can I use it without Strava?"**
   - Yes! HealthKit workouts work standalone
   - Strava adds power data and social features

5. **"How does it compare to Whoop/Oura?"**
   - More cycling-specific (power zones, TSS, CTL/ATL)
   - AI coaching vs just metrics
   - One-time purchase vs subscription hardware

---

## Presentation Tips

**Visual Aids:**
- Use iPhone simulator for demo (larger screen)
- Prepare screenshots for each slide
- Have backup video recording of demo

**Timing:**
- Stick to 3-5 minutes per section
- Leave 5 minutes for Q&A buffer
- Practice demo flow (aim for 6-7 minutes)

**Engagement:**
- Ask "Who here uses Whoop/Oura/Garmin?" at start
- Show real data from your own training
- Explain sports science in simple terms

**Backup Plan:**
- Have screenshots if live demo fails
- Prepare video recording of key features
- Have printed architecture diagram

---

## Key Takeaways

**For the Audience:**
1. VeloReady combines recovery science with cycling-specific training intelligence
2. Built with modern iOS tech stack (Swift, SwiftUI, AI, ML)
3. Solves real problems for serious amateur cyclists
4. Production-ready with clear roadmap

**For You:**
1. Demonstrate technical depth (architecture, algorithms, AI)
2. Show business acumen (market gap, pricing, roadmap)
3. Highlight problem-solving (race conditions, auth, performance)
4. Prove execution capability (working app, comprehensive features)
