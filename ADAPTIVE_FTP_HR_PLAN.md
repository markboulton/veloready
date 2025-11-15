# Adaptive FTP/VO2 with HR Support - Implementation Plan

## Overview
Enable FTP and VO2 max calculations for users without power meters by using heart rate data.

## Three-Tier System

### 1. Free Users
- **FTP**: Use basic Coggan estimate (e.g., 200W or 2.5 W/kg baseline)
- **VO2 max**: Use age/gender-based estimate
- **Display**: Show "Estimated" label
- **Zones**: Basic Coggan percentage-based zones

### 2. Pro Users WITHOUT Power Meter
- **FTP**: Estimate from LTHR (lactate threshold HR)
  - Formula: FTP ≈ (LTHR% of maxHR) × bodyWeight × efficiency × VO2conversion
  - Alternative: Use Coggan HR-to-power relationships
- **VO2 max**: Estimate from maxHR, age, resting HR
  - Formula: VO2max ≈ 15 × (maxHR / restingHR)
- **Display**: Show "Adaptive (HR-based)" label with sparkline
- **Zones**: Adaptive zones based on LTHR

### 3. Pro Users WITH Power Meter
- **FTP**: Current power-based adaptive calculation
- **VO2 max**: Calculated from FTP + weight
- **Display**: Show "Adaptive" with sparkline and confidence score
- **Zones**: Current adaptive power zones

## Implementation Steps

### 1. AthleteProfileManager Changes
- [ ] Add `hasPowerMeterData(activities:) -> Bool` method
- [ ] Add `estimateFTPFromHR(maxHR:lthr:weight:) -> Double?` method
- [ ] Add `estimateVO2MaxFromHR(maxHR:restingHR:age:) -> Double?` method
- [ ] Add `getCogganDefaultFTP(weight:) -> Double` method
- [ ] Add `getCogganDefaultVO2Max(age:gender:) -> Double` method
- [ ] Modify `computeFromActivities()` to use three-tier logic

### 2. Card ViewModel Changes
- [ ] Update `AdaptiveFTPCardViewModel` to detect power meter and show appropriate values
- [ ] Update `AdaptiveVO2MaxCardViewModel` similarly
- [ ] Add labels to distinguish between "Estimated", "Adaptive (HR)", and "Adaptive (Power)"

### 3. Adaptive Performance Page
- [ ] Update `AdaptivePerformanceViewModel` to use same three-tier logic
- [ ] Update UI to show data source (estimated/HR-based/power-based)

## Key Formulas

### HR-Based FTP Estimation
```
// Method 1: LTHR-based (Coggan)
FTP_watts = (LTHR / maxHR) * reference_watts_per_heartbeat * weight

// Method 2: Simplified Coggan
LTHR_percentage = LTHR / maxHR
FTP_watts = weight_kg * (2.0 + (LTHR_percentage - 0.85) * 10)
// Assumes 85% maxHR = ~2.5 W/kg, scales from there

// Method 3: From estimated VO2max
VO2max = 15 * (maxHR / restingHR)  // Cooper formula
FTP_W_per_kg = (VO2max - 7) / 10.8  // Reverse of existing formula
FTP = FTP_W_per_kg * weight
```

### VO2 Max from HR
```
// Cooper formula (validated for trained athletes)
VO2max = 15.3 × (maxHR / restingHR)

// Age-adjusted
age_factor = 1 - (age - 25) * 0.01  // Decline ~1% per year after 25
VO2max_adjusted = VO2max * age_factor
```

### Coggan Defaults (Free Users)
```
// Power
default_FTP = weight_kg * 2.5  // Average recreational cyclist
// OR fixed 200W if no weight

// VO2 Max (age and gender-based)
male_vo2_base = 50 - (age - 25) * 0.5
female_vo2_base = 45 - (age - 25) * 0.5
```

## Testing Plan
1. Test with Pro user who has power data → should use current adaptive
2. Test with Pro user who only has HR data → should estimate from HR
3. Test with Free user → should show basic Coggan estimates
4. Verify sparklines appear correctly for Pro users only
5. Verify labels distinguish between data sources

## Files to Modify
- `/VeloReady/Core/Models/AthleteProfile.swift` (main logic)
- `/VeloReady/Features/Today/Views/Components/AdaptiveFTPCard.swift`
- `/VeloReady/Features/Today/Views/Components/AdaptiveVO2MaxCard.swift`
- `/VeloReady/Features/Today/Views/DetailViews/AdaptivePerformanceDetailView.swift`
