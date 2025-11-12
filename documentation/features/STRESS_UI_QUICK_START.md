# Stress UI - Quick Start Guide

**Quick reference for testing the new stress monitoring feature**

---

## 🎯 How to Test (30 seconds)

1. **Open VeloReady** → **Settings** → **Debug** → **Features**
2. Scroll to **"Simulations"** section
3. Toggle **"Show Stress Alert"** to **ON**
4. Go back to **Today** tab
5. You should see an **amber banner** under the rings
6. Tap the banner to see the full **Stress Analysis** sheet

---

## 📍 What You'll See

### 1. Today View - Stress Banner
```
┌──────────────────────────────────────┐
│   ◯         ◯         ◯              │
│  Recovery   Sleep    Strain          │
│   72         85        12.8          │
│                                      │
│  ⚠️  High Training Stress            │
│  Your body is showing signs of       │
│  accumulated stress.    Details →    │
│                                      │
└──────────────────────────────────────┘
```

**Appearance:**
- Amber/orange background (10% opacity)
- Amber border (30% opacity)
- Rounded corners (12px)
- Warning icon + message + blue "Details" link

### 2. Stress Analysis Sheet
**Tap banner to open comprehensive breakdown:**

**Current State:**
- Acute Stress: 72 🟠
- Chronic Stress: 78 🟠  
- Trend: ↗ Increasing

**30-Day Trend:**
- Bar chart visualization
- Shows stress progression over time

**Contributors:**
- Training Load: High (28 pts)
- Sleep Quality: Elevated (15 pts)
- HRV: Elevated (12 pts)
- Temperature: Elevated (8 pts)

**Recommendations:**
- ✅ Implement recovery week NOW
- Reduce volume by 50%
- Keep intensity at Z2 only
- Prioritize 8+ hours sleep

### 3. Recovery Factors Card
**Location:** Recovery Detail View (tap Recovery ring → scroll down)

```
┌──────────────────────────────────────┐
│  Recovery Breakdown                  │
│  Factors contributing to your score  │
│                                      │
│  Stress                          Low │
│  ████░░░░░░░░░░░░░░░░░ (white bar)  │
│                                      │
│  HRV                         Optimal │
│  ████████████████████░░░░            │
│                                      │
│  RHR                         Optimal │
│  ████████████████░░░░░░              │
│                                      │
│  Sleep                       Optimal │
│  ████████████████████░░░░            │
│                                      │
│  Form (Training Load)            Good│
│  ███████████░░░░░░░░░                │
│                                      │
└──────────────────────────────────────┘
```

**Features:**
- White progress bars (2px height)
- Status colored and aligned right
- Sorted by importance (weight)
- Stress uses inverted labels (Low = good)

---

## 🎨 Design Highlights

### Colors
- **Elevated Stress:** Amber (`ColorScale.amberAccent`)
- **High Stress:** Red (`ColorScale.redAccent`)
- **Optimal:** Green (`ColorScale.greenAccent`)
- **Good:** Blue (`ColorScale.blueAccent`)
- **Progress Bars:** White on dark background

### Typography
- **Banner:** `.caption` (13pt)
- **Progress Labels:** `.caption` (matches chart labels)
- **Sheet Content:** `.subheadline` (15pt)
- **Metrics:** `.title3` (20pt bold)

### Spacing
- **Card Padding:** `Spacing.md` (16px)
- **Section Spacing:** `Spacing.lg` (24px)
- **Progress Bar Height:** 2px
- **Corner Radius:** 12px (banner), 16px (cards)

---

## 🧪 Testing Checklist

- [ ] Banner appears under rings
- [ ] Banner has amber styling
- [ ] Banner is tappable
- [ ] Sheet slides up smoothly
- [ ] All 5 sections render correctly
- [ ] Contributors show icons + descriptions
- [ ] Trend chart displays
- [ ] Recovery Factors Card appears in Recovery Detail
- [ ] Progress bars animate
- [ ] Status labels are colored
- [ ] Stress shows "Low" for good values
- [ ] Debug switch enables/disables banner

---

## 🐛 Troubleshooting

### Banner Not Showing?
1. Check debug toggle is ON
2. Verify you're on Today tab
3. Make sure HealthKit is authorized

### Sheet Not Opening?
1. Tap directly on the banner (full width)
2. Check console for any errors

### Recovery Card Not Showing?
1. Tap Recovery ring from Today view
2. Scroll down past the large ring
3. Should be first card

### Progress Bars Not Animating?
- They animate on scroll/appear
- Try scrolling away and back

---

## 📱 Demo Mode

**Perfect for Screenshots:**
1. Enable debug switch
2. Fresh app launch shows all animations
3. Banner → Sheet flow demonstrates feature
4. Recovery Card shows comprehensive breakdown

---

## 🔄 To Disable

1. **Settings** → **Debug** → **Features**
2. Toggle **"Show Stress Alert"** to **OFF**
3. Banner disappears
4. Recovery Factors Card stays (shows real data)

---

## 📊 What's Real vs Mock?

**Mock Data (Debug Mode):**
- Stress alert values (72, 78)
- Contributors breakdown
- 30-day trend chart

**Real Data (Always):**
- Recovery factors in Recovery Card
- HRV, RHR, Sleep, Form scores
- Progress bar percentages

---

## 💡 Tips

1. **Best View:** iPhone in portrait mode
2. **Dark Mode:** Stress banner looks great in both modes
3. **Animations:** Scroll slowly to see progress bar animations
4. **Details:** Spend time in the sheet - lots of info!

---

## 🎬 Next Steps

After testing the UI:
1. Provide feedback on layout/styling
2. Review content strings for clarity
3. Test on different screen sizes
4. Check accessibility with VoiceOver

**Phase 2 will add:**
- Real stress calculations
- Historical tracking
- Smart alerting thresholds
- Dismissal logic

---

**Questions?** Check `STRESS_UI_IMPLEMENTATION.md` for full technical details.

**Ready to test!** 🚀

