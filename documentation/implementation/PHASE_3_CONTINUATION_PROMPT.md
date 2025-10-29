# Phase 3 Continuation Prompt

**Date Started:** October 23, 2025, 3:26pm UTC+01:00  
**Last Updated:** October 23, 2025, 4:42pm UTC+01:00  
**Current Progress:** 4/16 cards migrated (25%)  
**Status:** IN PROGRESS - Systematic card migration to atomic components

---

## 🎯 Objective

Complete Phase 3: Component System Modernization by migrating ALL remaining cards to atomic design components, integrating them into views, and deleting old implementations.

---

## ✅ What's Already Done

### Atomic Components Created (9 total)
Located in `/Design/`:
- **Atoms:** VRText, VRBadge
- **Molecules:** CardHeader, CardMetric, CardFooter
- **Organisms:** CardContainer, ScoreCard, ChartCard, MetricStatCard

### Cards Already Migrated (4/16 = 25%)

**LIVE in Production:**
1. **StepsCardV2** - `/Features/Today/Views/Components/StepsCardV2.swift`
   - Integrated in TodayView (line 480)
   - Uses: CardContainer, CardHeader, CardMetric
   - Design tokens: Spacing, Icons, ColorScale
   - CommonContent: Metrics.steps, Units

2. **CaloriesCardV2** - `/Features/Today/Views/Components/CaloriesCardV2.swift`
   - Integrated in TodayView (line 491)
   - Uses: CardContainer, CardHeader, CardMetric, VRText
   - Design tokens: ColorScale.amberAccent, Spacing

**Created (Pending Integration):**
3. **DebtMetricCardV2** - `/Features/Today/Views/Components/DebtMetricCardV2.swift`
   - Uses: CardContainer, CardHeader, VRText
   - Design tokens: Spacing, Icons, Color.text
   - CommonContent: TodayContent.DebtMetrics

4. **HRVTrendCardV2** - `/Features/Trends/Views/Components/HRVTrendCardV2.swift`
   - Uses: ChartCard organism
   - Maintains original chart logic
   - Badge: IMPROVING/DECLINING/STABLE
   - Design tokens: ColorScale.hrvColor

### Old Files Deleted (4)
- ❌ StepsCard.swift
- ❌ CaloriesCard.swift
- ❌ ReadinessCardView.swift
- ❌ SimpleMetricCard.swift

### Build Status
✅ ALL BUILDS PASSING

---

## ⏳ Remaining Work: 12 Cards (75%)

### Today Cards (2)
- **HealthWarningsCard** - Complex (illness + wellness alerts)
- **LatestActivityCard** - Complex (311 lines, includes map)
- SkeletonCard (skip - loading state)
- UnifiedActivityCard (skip - navigation wrapper)

### Trends Cards (10) - Use ChartCard Pattern
1. **RecoveryTrendCard** - `/Features/Trends/Views/Components/RecoveryTrendCard.swift`
2. **RestingHRCard** - `/Features/Trends/Views/Components/RestingHRCard.swift`
3. **StressLevelCard** - `/Features/Trends/Views/Components/StressLevelCard.swift`
4. **FTPTrendCard** - `/Features/Trends/Views/Components/FTPTrendCard.swift`
5. **OvertrainingRiskCard** - `/Features/Trends/Views/Components/OvertrainingRiskCard.swift`
6. **PerformanceOverviewCard** - `/Features/Trends/Views/Components/PerformanceOverviewCard.swift`
7. **RecoveryVsPowerCard** - `/Features/Trends/Views/Components/RecoveryVsPowerCard.swift`
8. **TrainingLoadTrendCard** - `/Features/Trends/Views/Components/TrainingLoadTrendCard.swift`
9. **TrainingPhaseCard** - `/Features/Trends/Views/Components/TrainingPhaseCard.swift`
10. **WeeklyTSSTrendCard** - `/Features/Trends/Views/Components/WeeklyTSSTrendCard.swift`

---

## 🔧 Migration Pattern

### For Trends Cards (Use ChartCard)
```swift
import SwiftUI
import Charts

struct [CardName]V2: View {
    let data: [TrendsViewModel.TrendDataPoint]
    let timeRange: TrendsViewModel.TimeRange
    
    var body: some View {
        ChartCard(
            title: TrendsContent.Cards.[title],
            subtitle: subtitleText,
            badge: badge,
            footerText: footerText
        ) {
            if data.isEmpty {
                // Empty state
            } else {
                // Original chart content
            }
        }
    }
}
```

### For Today Cards (Use CardContainer)
```swift
struct [CardName]V2: View {
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: "...",
                subtitle: "...",
                badge: badge,
                action: action
            ),
            style: .standard
        ) {
            // Card content
        }
    }
}
```

---

## 📋 Next Steps (In Order)

### Step 1: Batch Create Trends V2 Cards (5 cards)
1. RecoveryTrendCardV2
2. RestingHRCardV2
3. StressLevelCardV2
4. FTPTrendCardV2
5. OvertrainingRiskCardV2

**Pattern:** Wrap original chart in ChartCard, use design tokens, use TrendsContent

### Step 2: Batch Create Remaining Trends V2 Cards (5 cards)
1. PerformanceOverviewCardV2
2. RecoveryVsPowerCardV2
3. TrainingLoadTrendCardV2
4. TrainingPhaseCardV2
5. WeeklyTSSTrendCardV2

**Pattern:** Same as Step 1

### Step 3: Migrate Complex Today Cards (2 cards)
1. HealthWarningsCardV2 - Keep illness/wellness logic, wrap in CardContainer
2. LatestActivityCardV2 - Keep map/metadata, wrap in CardContainer

### Step 4: Integrate All V2 Cards into Views
- Replace old card usages in TodayView
- Replace old card usages in TrendsView
- Verify all builds pass

### Step 5: Delete All Old Card Files
- Delete all original card files after V2 integration verified
- Verify no references remain

### Step 6: Final Verification
- Build entire project
- Verify no compilation errors
- Commit final state

---

## ✅ Requirements for All Migrations

**Design Tokens:**
- Use Spacing.md, Spacing.sm, Spacing.xs (NOT hard-coded numbers)
- Use Icons from Icons enum (NOT hard-coded strings)
- Use ColorScale.* (NOT hard-coded colors)
- Use Color.text.primary, Color.text.secondary (NOT Color.primary)

**Content Abstraction:**
- Use CommonContent, TodayContent, TrendsContent (NOT hard-coded strings)
- Extract new strings to appropriate content files if needed

**Architecture:**
- Leverage existing services (LiveActivityService, HealthKitManager, etc.)
- Maintain caching behavior
- Keep performance optimizations

**Components:**
- Use atomic components: CardContainer, CardHeader, CardMetric, CardFooter, VRText, VRBadge
- Use organism components: ChartCard, ScoreCard, MetricStatCard
- No hard-coded layouts

**Build & Commit:**
- Build and verify after EACH card migration
- Commit after every 2-3 cards with clear message
- Include progress count in commit message (e.g., "Cards 5-7/16")

---

## 📊 Tracking

**Completed:** 4/16 (25%)
- StepsCardV2 ✅ LIVE
- CaloriesCardV2 ✅ LIVE
- DebtMetricCardV2 ✅ Created
- HRVTrendCardV2 ✅ Created

**Remaining:** 12/16 (75%)
- Trends: 10 cards
- Today: 2 cards

**Build Status:** ✅ All passing

---

## 🚀 Starting Point for Next Session

1. Read this prompt
2. Create RecoveryTrendCardV2 using ChartCard pattern
3. Build and verify
4. Commit with message: "Cards 5-6/16: RecoveryTrend + [next]"
5. Continue batch creating remaining cards
6. Integrate all V2 cards
7. Delete old files
8. Final verification

---

## 📝 Important Notes

- **All migrations must use design tokens** - NO hard-coded values
- **All migrations must use CommonContent** - NO hard-coded strings
- **Build and verify after each card** - Catch errors early
- **Commit frequently** - Every 2-3 cards
- **Follow atomic design pattern** - Use existing components
- **Maintain existing functionality** - Don't simplify away features

---

## 🎯 Success Criteria

✅ All 16 cards migrated to V2 versions  
✅ All V2 cards use atomic components  
✅ All V2 cards use design tokens  
✅ All V2 cards use CommonContent  
✅ All old card files deleted  
✅ All views updated to use V2 cards  
✅ Final build passes with no errors  
✅ No hard-coded values anywhere  

---

**Ready to continue? Start with Step 1: Create RecoveryTrendCardV2**
