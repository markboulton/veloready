# VeloReady StoreKit Implementation Plan

## Executive Summary

VeloReady has **excellent infrastructure already in place** for StoreKit 2 integration. The app has a complete subscription system architecture with:
- ✅ `SubscriptionManager` using StoreKit 2 APIs
- ✅ `ProFeatureConfig` for centralized feature gating
- ✅ Comprehensive paywall UI with `PaywallView`
- ✅ Pro upgrade cards throughout the app
- ✅ Feature gate components
- ✅ Content abstraction for all copy

**What's needed**: Configure App Store Connect, add entitlements, and connect the existing implementation to real subscription products.

---

## Current State Analysis

### ✅ Already Implemented

#### 1. Core Subscription Infrastructure
- **`SubscriptionManager.swift`** (StoreKit 2)
  - Product loading (`Product.products(for:)`)
  - Purchase flow with verification
  - Transaction listener for updates
  - Subscription status tracking (subscribed/trial/free)
  - Receipt validation using `checkVerified()`
  - Restore purchases functionality
  - Product IDs defined:
    - Monthly: `com.veloready.pro.monthly`
    - Yearly: `com.veloready.pro.yearly`

#### 2. Feature Gating System
- **`ProFeatureConfig.swift`**
  - Centralized Pro access control (`hasProAccess`)
  - 16 feature categories defined:
    - Multi-service sync (Strava, TrainingPeaks, Garmin, Wahoo)
    - Dashboard trends (weekly/monthly)
    - AI features (coaching, summaries, insights)
    - Advanced recovery (HRV trends, forecasting)
    - Training charts (CTL/ATL/TSB, VO₂, form)
    - Load analysis (7-day, 28-day)
    - Sleep analysis (AI summary, efficiency, debt)
    - Training focus (7-day recommendations)
    - Map overlays (HR/power gradients)
    - Correlation insights
    - Data export (CSV/JSON)
    - Cloud backup
    - Custom themes
    - Priority support
  - Development testing bypass
  - State persistence to UserDefaults

#### 3. UI Components
- **`PaywallView.swift`**: Full-featured subscription screen
  - Plan selector (monthly/yearly)
  - Trial banner
  - Feature list with benefits
  - CTA button
  - Error handling
  - Restore purchases button

- **`ProUpgradeCard.swift`**: Inline upgrade prompts
  - Benefits display
  - "Learn More" link support
  - Dark/light mode adaptive
  - Tappable to open paywall

- **`ProFeatureGate.swift`**: Conditional content rendering
  - Shows Pro content if subscribed
  - Shows upgrade card if free

- **`ProBadgeButton.swift`**: Compact Pro indicator

#### 4. Content Abstraction
- **`PaywallContent.swift`**: All paywall copy centralized
- **`ProUpgradeContent.swift`**: Pre-defined upgrade prompts for each feature
- **`OnboardingContent.Subscription`**: Trial/subscription onboarding copy

#### 5. Integration Points
- Onboarding flow includes subscription step (`SubscriptionStepView`)
- Settings has subscription management
- 16+ Pro upgrade cards throughout app
- Navigation links with Pro gates

---

## What Needs to Be Done

### Phase 1: App Store Connect Setup (Critical)

#### 1.1 Create In-App Purchase Products
**Action**: Configure in App Store Connect

**Products to Create**:

```
Product 1 - Monthly Subscription
  Product ID: com.veloready.pro.monthly
  Type: Auto-Renewable Subscription
  Subscription Group: VeloReady Pro
  Price: $9.99/month (Tier 10)
  Free Trial: 7 days
  Display Name: VeloReady Pro Monthly
  Description: Unlock all VeloReady Pro features with monthly billing
  
Product 2 - Annual Subscription
  Product ID: com.veloready.pro.yearly
  Type: Auto-Renewable Subscription
  Subscription Group: VeloReady Pro
  Price: $71.88/year (equivalent to $5.99/month, 40% savings)
  Free Trial: 7 days
  Display Name: VeloReady Pro Yearly
  Description: Unlock all VeloReady Pro features with annual billing (Best Value!)
```

**Subscription Group Settings**:
- Group Name: `VeloReady Pro`
- Family Sharing: Enable (allows Pro to be shared with family members)
- Renewal: Monthly subscription auto-upgrades to yearly if user switches

#### 1.2 Introductory Offers
Configure 7-day free trial for both products:
- Type: Free Trial
- Duration: 7 days
- Eligibility: First-time subscribers only
- Cancellation: User can cancel anytime during trial with no charge

#### 1.3 Promotional Offers (Optional)
Consider for marketing campaigns:
- Win-back offer: 30% off for 3 months for lapsed subscribers
- Black Friday: 50% off yearly plan for new subscribers

---

### Phase 2: Xcode Project Configuration

#### 2.1 Add StoreKit Configuration File
**File**: `VeloReady.storekit`

**Purpose**: Local testing without App Store Connect

**Contents**:
```json
{
  "products": [
    {
      "id": "com.veloready.pro.monthly",
      "type": "auto-renewable",
      "displayName": "VeloReady Pro Monthly",
      "description": "Monthly subscription to VeloReady Pro",
      "price": 9.99,
      "subscriptionGroupId": "veloready_pro",
      "subscriptionDuration": "P1M",
      "locale": "en_US"
    },
    {
      "id": "com.veloready.pro.yearly",
      "type": "auto-renewable",
      "displayName": "VeloReady Pro Yearly",
      "description": "Annual subscription to VeloReady Pro",
      "price": 71.88,
      "subscriptionGroupId": "veloready_pro",
      "subscriptionDuration": "P1Y",
      "locale": "en_US"
    }
  ],
  "subscriptionGroups": [
    {
      "id": "veloready_pro",
      "displayName": "VeloReady Pro"
    }
  ]
}
```

**How to Add**:
1. Xcode → File → New → File → StoreKit Configuration File
2. Name: `VeloReady.storekit`
3. Add to VeloReady target
4. Edit scheme → Run → Options → StoreKit Configuration → Select `VeloReady.storekit`

#### 2.2 Add In-App Purchase Capability
**Action**: Enable in Xcode

**Steps**:
1. Select VeloReady target
2. Signing & Capabilities tab
3. Click "+ Capability"
4. Add "In-App Purchase"

**Result**: Adds entitlement to `VeloReady.entitlements`:
```xml
<key>com.apple.developer.in-app-payments</key>
<true/>
```

#### 2.3 Update Info.plist (If Needed)
Check if `SKAdNetwork` items are present for attribution (optional but recommended for marketing):
```xml
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

---

### Phase 3: Code Updates

#### 3.1 Update SubscriptionManager Error Handling
**File**: `VeloReady/Core/Services/SubscriptionManager.swift`

**Current State**: ✅ Already excellent

**Optional Enhancement**: Add analytics/logging for subscription events

```swift
// Add after successful purchase
func purchase(_ product: Product) async throws {
    // ... existing code ...
    
    case .success(let verification):
        // ... existing code ...
        
        // OPTIONAL: Add analytics
        Analytics.logEvent("subscription_purchased", parameters: [
            "product_id": product.id,
            "price": product.price,
            "currency": product.priceFormatStyle.currencyCode ?? "USD"
        ])
}
```

#### 3.2 Add Subscription Status Debug View (Optional)
**File**: `VeloReady/Features/Debug/Views/SubscriptionDebugView.swift` (NEW)

**Purpose**: Internal testing tool to verify subscription state

```swift
import SwiftUI

struct SubscriptionDebugView: View {
    @ObservedObject var manager = SubscriptionManager.shared
    @ObservedObject var config = ProFeatureConfig.shared
    
    var body: some View {
        List {
            Section("Subscription Status") {
                LabeledContent("Status", value: "\(manager.subscriptionStatus)")
                LabeledContent("Has Pro Access", value: "\(config.hasProAccess)")
                LabeledContent("Is Pro User", value: "\(config.isProUser)")
                LabeledContent("Is Trial", value: "\(config.isInTrialPeriod)")
                LabeledContent("Trial Days", value: "\(config.trialDaysRemaining)")
            }
            
            Section("Products") {
                if let monthly = manager.monthlyProduct {
                    LabeledContent("Monthly", value: monthly.displayPrice)
                }
                if let yearly = manager.yearlyProduct {
                    LabeledContent("Yearly", value: yearly.displayPrice)
                }
            }
            
            Section("Testing") {
                Button("Reload Products") {
                    Task {
                        await manager.loadProducts()
                    }
                }
                
                Button("Refresh Status") {
                    Task {
                        await manager.updateSubscriptionStatus()
                    }
                }
                
                Button("Restore Purchases") {
                    Task {
                        await manager.restorePurchases()
                    }
                }
            }
            
            #if DEBUG
            Section("Debug Controls") {
                Toggle("Bypass Subscription", isOn: $config.bypassSubscriptionForTesting)
            }
            #endif
        }
        .navigationTitle("Subscription Debug")
    }
}
```

**Add to Settings**: Link from Settings → Debug section

#### 3.3 Verify ProFeatureConfig Integration
**File**: `VeloReady/Core/Config/ProFeatureConfig.swift`

**Current State**: ✅ Already integrated with SubscriptionManager

**Verify**: Line 216-238 correctly updates from SubscriptionManager

**Already Working**:
```swift
private func updateProFeatureConfig() {
    Task { @MainActor in
        let config = ProFeatureConfig.shared
    
    switch subscriptionStatus {
    case .subscribed:
        config.isProUser = true
        config.isInTrialPeriod = false
        config.trialDaysRemaining = 0
        
    case .trial(let daysRemaining):
        config.isProUser = false
        config.isInTrialPeriod = true
        config.trialDaysRemaining = daysRemaining
        
    case .notSubscribed:
        config.isProUser = false
        config.isInTrialPeriod = false
        config.trialDaysRemaining = 0
    }
    
        config.saveSubscriptionState()
    }
}
```

**No changes needed** ✅

---

### Phase 4: Testing Strategy

#### 4.1 Local Testing with StoreKit Configuration File
**Environment**: Xcode Simulator/Device (Development)

**Steps**:
1. Enable StoreKit config in scheme settings
2. Run app in simulator
3. Test flows:
   - ✅ Load products
   - ✅ Display paywall with correct prices
   - ✅ Purchase monthly subscription
   - ✅ Verify Pro features unlock
   - ✅ Purchase yearly subscription
   - ✅ Verify upgrade from monthly → yearly
   - ✅ Test 7-day trial flow
   - ✅ Test restore purchases
   - ✅ Test subscription expiration
   - ✅ Test subscription cancellation

**Advantages**:
- No App Store Connect needed
- Instant testing
- Repeatable
- No real money

#### 4.2 Sandbox Testing
**Environment**: TestFlight or Xcode with Sandbox Account

**Setup**:
1. App Store Connect → Users and Access → Sandbox Testers
2. Create test accounts:
   - `veloready.test1@icloud.com`
   - `veloready.test2@icloud.com`
   - `veloready.test3@icloud.com`

**Test Scenarios**:
- [ ] New user → Monthly subscription → 7-day trial
- [ ] New user → Yearly subscription → 7-day trial
- [ ] Trial user → Convert to paid after 7 days
- [ ] Trial user → Cancel before trial ends
- [ ] Paid user → Upgrade monthly → yearly
- [ ] Paid user → Cancel subscription
- [ ] Paid user → Resubscribe after cancellation
- [ ] Restore purchases on new device
- [ ] Family Sharing (if enabled)

**Accelerated Timeline**:
Sandbox subscriptions have accelerated renewal periods:
- 1 month = 5 minutes
- 1 year = 1 hour
- 7-day trial = 3 minutes

#### 4.3 Production Testing (TestFlight)
**Environment**: TestFlight Internal Testing

**Steps**:
1. Upload build to App Store Connect
2. Enable for internal testing
3. Invite internal testers
4. Test complete purchase flows
5. Verify receipt validation works in production

**Critical Checks**:
- [ ] Products load correctly
- [ ] Prices display in local currency
- [ ] Purchase completes successfully
- [ ] Receipt validation works
- [ ] Features unlock immediately
- [ ] Subscription renews automatically
- [ ] Restore purchases works

---

### Phase 5: App Store Submission Requirements

#### 5.1 App Privacy Details
**Required in App Store Connect**

**Data Collection**:
```
Subscriptions:
  ✓ Subscription ID
  ✓ Purchase History
  ✓ Purchase Date
  
Purpose: App Functionality
Linked to User: Yes
Used for Tracking: No
```

**Update Privacy Policy**: Add section on subscription data handling

#### 5.2 Subscription Information
**Required for Review**

**Provide**:
- Clear description of Pro features
- Screenshots showing Free vs Pro differences
- Subscription terms visible in app
- Cancellation instructions
- Refund policy link

**In Paywall** (Already implemented ✅):
- Feature list
- Price display
- Trial terms
- Auto-renewal notice
- Terms of Service link
- Privacy Policy link

#### 5.3 Review Notes
**For App Review Team**

```
Subscription Testing:
- Sandbox account: veloready.test1@icloud.com (password: TestPass123!)
- Test card: Use sandbox test card (automatic)
- Free trial: 7 days (accelerated to 3 minutes in sandbox)

Pro Features Demonstrated:
- AI Coaching (Daily Brief, Ride Summaries)
- Advanced Charts (Training Load, Intensity, Form)
- Weekly/Monthly Trends
- Strava Integration
- Map Overlays (HR/Power gradients)

All Pro features clearly marked with PRO badge.
Free tier provides full core functionality (scores, activities, health data).
```

---

## Implementation Checklist

### Pre-Development
- [ ] Review current `SubscriptionManager.swift` implementation
- [ ] Verify product IDs match naming convention
- [ ] Decide on pricing ($9.99/month, $71.88/year confirmed?)
- [ ] Plan trial period duration (7 days recommended)

### App Store Connect
- [ ] Create app record (if not exists)
- [ ] Add Monthly subscription product (`com.veloready.pro.monthly`)
- [ ] Add Yearly subscription product (`com.veloready.pro.yearly`)
- [ ] Configure subscription group: "VeloReady Pro"
- [ ] Set up 7-day free trial introductory offer
- [ ] Add localized product descriptions
- [ ] Enable Family Sharing (recommended)
- [ ] Create sandbox test accounts (minimum 3)

### Xcode Configuration
- [ ] Add `VeloReady.storekit` configuration file
- [ ] Enable In-App Purchase capability
- [ ] Configure scheme to use StoreKit file
- [ ] Update entitlements

### Code Updates
- [ ] Add subscription debug view (optional but recommended)
- [ ] Add analytics events (optional)
- [ ] Verify error handling paths
- [ ] Test all Pro feature gates

### Testing
- [ ] Local testing with StoreKit config (all scenarios)
- [ ] Sandbox testing (all scenarios)
- [ ] TestFlight internal testing
- [ ] TestFlight external beta (optional)

### App Store Submission
- [ ] Update Privacy Policy
- [ ] Add App Privacy details in App Store Connect
- [ ] Provide subscription screenshots
- [ ] Add review notes with test account
- [ ] Submit for review

### Post-Launch
- [ ] Monitor subscription analytics
- [ ] Track conversion rates
- [ ] Monitor support requests
- [ ] A/B test pricing (if needed)

---

## Pricing Recommendations

### Current Plan (Recommended ✅)

```
Monthly: $9.99/month
Yearly:  $71.88/year ($5.99/month equivalent, 40% savings)
Trial:   7 days free
```

**Rationale**:
- **$9.99/month** is standard for fitness/training apps
- **40% annual savings** creates strong incentive to choose yearly
- **7-day trial** allows users to experience full value
- Competitive with similar apps:
  - TrainingPeaks: $19.99/month ($129/year)
  - Intervals.icu: €8/month (€72/year)
  - Strava: $11.99/month ($79.99/year)
  - VeloReady is well-positioned as premium but affordable

### Alternative Considerations

**Lower Price Point**:
```
Monthly: $7.99/month
Yearly:  $59.99/year ($5/month equivalent)
```
- Pros: Lower barrier to entry, faster growth
- Cons: Less revenue per user, may undervalue product

**Higher Price Point**:
```
Monthly: $12.99/month
Yearly:  $99.99/year ($8.33/month equivalent)
```
- Pros: Higher revenue per user, premium positioning
- Cons: May reduce conversion rate

**Recommendation**: Start with $9.99/month, monitor conversion, adjust after 3 months if needed.

---

## Revenue Projections

### Conservative Scenario
```
User Base:     1,000 active users
Conversion:    5% to paid (50 users)
Split:         30% monthly ($9.99) = 15 users = $149.85/month
               70% yearly ($71.88) = 35 users = $209.30/month
Monthly MRR:   $359.15
Annual MRR:    $4,309.80

After Apple's 30% cut:
Net Monthly:   $251.41
Net Annual:    $3,016.86
```

### Target Scenario (Year 1)
```
User Base:     5,000 active users
Conversion:    8% to paid (400 users)
Split:         25% monthly = 100 users = $999/month
               75% yearly = 300 users = $1,797/month
Monthly MRR:   $2,796
Annual MRR:    $33,552

After Apple's 30% cut:
Net Monthly:   $1,957.20
Net Annual:    $23,486.40
```

### Growth Scenario (Year 2)
```
User Base:     15,000 active users
Conversion:    10% to paid (1,500 users)
Split:         20% monthly = 300 users = $2,997/month
               80% yearly = 1,200 users = $5,990/month
Monthly MRR:   $8,987
Annual MRR:    $107,844

After Apple's 30% cut (reduced to 15% after year 1):
Net Monthly:   $7,639.95
Net Annual:    $91,667.40
```

**Note**: Apple reduces commission to 15% after subscriber is active for 1 year.

---

## Risk Mitigation

### Technical Risks

**Risk 1**: Receipt validation failures
- **Mitigation**: Use StoreKit 2's built-in verification (`checkVerified()`)
- **Already implemented** ✅

**Risk 2**: Subscription status not updating
- **Mitigation**: Transaction listener active at app launch
- **Already implemented** ✅

**Risk 3**: Family Sharing issues
- **Mitigation**: Test thoroughly in sandbox with multiple accounts
- **Action**: Add to test plan

### Business Risks

**Risk 1**: Low conversion rate (<3%)
- **Mitigation**: 
  - Strong onboarding showcasing Pro value
  - 7-day trial to experience features
  - Clear upgrade prompts throughout app
  - A/B test paywall copy

**Risk 2**: High churn rate (>10% monthly)
- **Mitigation**:
  - Focus on feature value delivery
  - Monitor usage analytics
  - Proactive engagement (push notifications)
  - Win-back campaigns for lapsed subscribers

**Risk 3**: App Store rejection
- **Mitigation**:
  - Follow App Store Review Guidelines exactly
  - Provide clear test instructions
  - Ensure all Pro features are clearly marked
  - Maintain valuable free tier

---

## Timeline Estimate

### Week 1: Setup & Configuration
- Day 1-2: App Store Connect setup (products, subscription group)
- Day 3-4: Xcode configuration (StoreKit file, entitlements)
- Day 5: Local testing with StoreKit config

### Week 2: Testing & Refinement
- Day 1-3: Sandbox testing (all scenarios)
- Day 4-5: Bug fixes and refinements

### Week 3: TestFlight & Submission
- Day 1-2: TestFlight internal testing
- Day 3: Final adjustments
- Day 4: App Store submission preparation
- Day 5: Submit to App Store

### Week 4: Review & Launch
- Day 1-3: App Review (typically 24-48 hours)
- Day 4-5: Launch preparation, monitoring setup

**Total**: 3-4 weeks from start to App Store launch

---

## Success Metrics

### Launch Week (Week 1)
- [ ] No critical bugs reported
- [ ] Subscription products loading successfully
- [ ] >90% purchase success rate
- [ ] <5% support tickets related to subscriptions

### First Month
- [ ] Achieve >3% conversion rate (free → trial)
- [ ] Achieve >60% trial → paid conversion
- [ ] <5% involuntary churn (failed payments)
- [ ] Positive App Store reviews mentioning Pro features

### First Quarter
- [ ] Achieve >5% overall conversion rate
- [ ] Achieve >70% trial → paid conversion
- [ ] <8% voluntary churn (cancellations)
- [ ] 50+ paid subscribers (conservative target)
- [ ] $500+ MRR (after Apple's cut)

### First Year
- [ ] 8-10% conversion rate
- [ ] 1,000+ paid subscribers
- [ ] $8,000+ MRR
- [ ] <10% churn rate
- [ ] 4.5+ App Store rating

---

## Support & Documentation Needs

### User-Facing Documentation

**Help Center Articles** (create on website):
1. "How to Subscribe to VeloReady Pro"
2. "What's Included in VeloReady Pro?"
3. "Managing Your Subscription"
4. "How to Cancel or Change Your Subscription"
5. "Refund Policy and Requests"
6. "Restoring Purchases on a New Device"
7. "Family Sharing for VeloReady Pro"

**In-App**:
- [ ] Add "Subscription FAQ" in Settings
- [ ] Add "Contact Support" button in paywall
- [ ] Add link to Terms of Service
- [ ] Add link to Privacy Policy

### Internal Documentation

**Runbooks**:
1. "Handling Subscription Support Tickets"
2. "Processing Refund Requests"
3. "Troubleshooting Purchase Issues"
4. "Monitoring Subscription Health"

**Analytics Dashboard**:
- Track daily/weekly/monthly conversions
- Monitor churn rate
- Track MRR growth
- Analyze paywall performance

---

## Next Steps

### Immediate Actions (This Week)
1. ✅ Review this implementation plan
2. [ ] Confirm pricing strategy ($9.99/month, $71.88/year)
3. [ ] Create App Store Connect account (if needed)
4. [ ] Set up subscription products in App Store Connect
5. [ ] Add StoreKit configuration file to Xcode

### Short-Term (Next 2 Weeks)
1. [ ] Local testing with StoreKit config
2. [ ] Create sandbox test accounts
3. [ ] Sandbox testing (all flows)
4. [ ] Add subscription debug view
5. [ ] Update Privacy Policy

### Medium-Term (Next 4 Weeks)
1. [ ] TestFlight internal testing
2. [ ] Submit to App Store
3. [ ] Plan launch communications
4. [ ] Set up analytics tracking
5. [ ] Prepare support documentation

---

## Conclusion

**VeloReady is exceptionally well-positioned for StoreKit integration.** The heavy lifting is already done:
- ✅ StoreKit 2 implementation complete
- ✅ Feature gating system robust
- ✅ UI components polished
- ✅ Content properly abstracted

**Estimated effort to launch**: 2-3 weeks with most time spent on App Store Connect setup and testing.

**Key Strengths**:
1. Modern StoreKit 2 implementation (not legacy)
2. Comprehensive Pro features (16 categories)
3. Clean UI/UX for subscriptions
4. Strong value proposition (AI, analytics, integrations)
5. Competitive pricing

**Recommended First Step**: Set up subscription products in App Store Connect this week, then proceed with local testing.

---

## Questions for Product Review

1. **Pricing Confirmation**: Confirm $9.99/month and $71.88/year pricing?
2. **Trial Duration**: 7 days confirmed? (vs 14 days or 30 days)
3. **Family Sharing**: Enable or not? (Recommended: Yes)
4. **Promotional Offers**: Plan any launch discounts?
5. **Feature Scope**: Any Pro features to add/remove before launch?
6. **Launch Timing**: Target date for App Store submission?
7. **Marketing**: Plan for announcing Pro subscription?

---

**Document Version**: 1.0  
**Last Updated**: October 29, 2025  
**Author**: AI Assistant  
**Status**: Draft for Review

