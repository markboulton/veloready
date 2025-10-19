# TSS Distribution Analysis - 120 Days of Ride Data

**Date:** October 16, 2025  
**FTP:** 212W  
**Data Source:** User's actual activity logs from FTP computation

---

## 📊 **Your 36 Activities with Power Data:**

| # | Activity | NP (W) | Duration | IF | TSS | Category |
|---|----------|--------|----------|-----|-----|----------|
| 1 | 2 x 10 | 177 | 48 min | 0.83 | 52 | Moderate |
| 2 | 20s | 154 | 40 min | 0.73 | 33 | Easy |
| 3 | Cycling | 125 | 19 min | 0.59 | 10 | Recovery |
| 4 | Cycling | 143 | 15 min | 0.67 | 10 | Recovery |
| 5 | 5 x 3 mixed | 177 | 54 min | 0.83 | 58 | Moderate |
| 6 | Shortened. Mechanical | 210 | 59 min | 0.99 | 95 | Hard |
| 7 | 4 x 8 | 173 | 37 min | 0.82 | 38 | Moderate-Easy |
| 8 | 4 reps | 157 | 35 min | 0.74 | 30 | Easy |
| 9 | Pedal Wye (ultra) | 197 | 340 min | 0.93 | 490 | EXTREME |
| 10 | 2 x 9 | 189 | 49 min | 0.89 | 61 | Moderate |
| 11 | 4 x 6 | 185 | 46 min | 0.87 | 55 | Moderate |
| 12 | 2 x 15 | 165 | 60 min | 0.78 | 60 | Moderate |
| 13 | 2 x 9 | 187 | 39 min | 0.88 | 47 | Moderate |
| 14 | Morning Ride | 209 | 170 min | 0.99 | 275 | Very Hard |
| 15 | mixed - mechanical indoors | 176 | 68 min | 0.83 | 73 | Hard |
| 16 | Lunch Ride | 182 | 11 min | 0.86 | 13 | Easy |
| 17 | Morning Ride | 201 | 98 min | 0.95 | 146 | Hard |
| 18 | Hollins lane blast | 216 | 71 min | 1.02 | 122 | Hard |
| 19 | mixed. Up | 210 | 45 min | 0.99 | 73 | Hard |
| 20 | Afternoon Ride | 186 | 83 min | 0.88 | 106 | Hard |
| 21 | OTHER | 98 | 310 min | 0.46 | 108 | Hard (volume) |
| 22 | 4 x 6 | 176 | 41 min | 0.83 | 44 | Moderate |
| 23 | Afternoon Ride | 200 | 98 min | 0.94 | 144 | Hard |
| 24 | Lunch Ride | 198 | 126 min | 0.93 | 181 | Very Hard |
| 25 | Session 2: mixed | 156 | 49 min | 0.74 | 42 | Moderate |
| 26 | 8 x 4 | 149 | 47 min | 0.70 | 36 | Moderate-Easy |
| 27 | Back in: 2 x 5 mixed | 152 | 32 min | 0.72 | 26 | Easy |
| 28 | 6 x 4 | 146 | 42 min | 0.69 | 31 | Easy |
| 29 | Afternoon Ride | 145 | 31 min | 0.68 | 22 | Easy |
| 30 | back in: 30 mins | 145 | 27 min | 0.68 | 20 | Easy |
| 31 | Afternoon Ride | 146 | 21 min | 0.69 | 16 | Easy |
| 32 | 6 x 5 (too hot) | 176 | 30 min | 0.83 | 32 | Easy |
| 33 | Lunch Ride | 212 | 171 min | 1.00 | 285 | Very Hard |
| 34 | 2 x 20 | 185 | 51 min | 0.87 | 64 | Moderate |
| 35 | Afternoon Ride | 203 | 127 min | 0.96 | 193 | Very Hard |
| 36 | 2 x 20 (bailed, too hot) | 140 | 8 min | 0.66 | 6 | Recovery |

---

## 📈 **TSS Distribution Statistics:**

### **Summary Stats:**
- **Total activities:** 36
- **TSS Range:** 6 - 490
- **Mean TSS:** 85.4
- **Median TSS:** 51.5
- **Standard Deviation:** ~85

### **TSS Distribution by Range:**

| TSS Range | Count | % | Category | Your Activities |
|-----------|-------|---|----------|-----------------|
| 0-20 | 5 | 14% | Recovery | Cycling, short rides |
| 21-40 | 8 | 22% | Easy | 4x8, 4 reps, 6x4, etc. |
| 41-60 | 8 | 22% | Moderate | 2x10, 2x15, 4x6, 2x9 |
| 61-100 | 6 | 17% | Hard | Mixed indoors, Hollins |
| 101-150 | 5 | 14% | Very Hard | Morning rides, Lunch |
| 151-200 | 3 | 8% | Very Hard | Weekend epics |
| 200+ | 1 | 3% | EXTREME | Pedal Wye (490) |

---

## 🎯 **Percentile Analysis:**

| Percentile | TSS | Intensity |
|------------|-----|-----------|
| 10th | 10 | Recovery |
| 25th (Q1) | 26 | Easy |
| 50th (Median) | 51.5 | Moderate |
| 75th (Q3) | 106 | Hard |
| 90th | 181 | Very Hard |
| 95th | 285 | Extreme |
| 99th | 490 | Ultra-Extreme |

---

## 🎯 **RECOMMENDED STRAIN BANDS (Data-Driven):**

### **Option 1: Quartile-Based (Natural Distribution)**

Based on your actual TSS quartiles:

```swift
case 0..<4.0: return .recovery     // 0-25th percentile (TSS 0-26)
case 4.0..<7.0: return .low        // 25-50th percentile (TSS 26-52)
case 7.0..<10.0: return .moderate  // 50-75th percentile (TSS 52-106)
case 10.0..<13.0: return .high     // 75-90th percentile (TSS 106-181)
default: return .extreme           // 90th+ percentile (TSS 181+)
```

### **Option 2: Standard Distribution (Balanced)**

```swift
case 0..<5.0: return .low          // TSS 0-35 (recovery/easy)
case 5.0..<8.0: return .moderate   // TSS 35-75 (normal training)
case 8.0..<11.0: return .high      // TSS 75-130 (hard training)
case 11.0..<14.0: return .veryHard // TSS 130-200 (weekend epics)
default: return .extreme           // TSS 200+ (ultra-endurance)
```

### **Option 3: Your Current Usage Pattern**

Based on what you actually do:

```swift
case 0..<5.5: return .low          // TSS 0-40 (easy/recovery)
case 5.5..<8.5: return .moderate   // TSS 40-80 (weekday training)
case 8.5..<12.0: return .hard      // TSS 80-150 (hard sessions)
case 12.0..<14.5: return .veryHard // TSS 150-250 (weekend epics)
default: return .extreme           // TSS 250+ (ultra rides like Pedal Wye)
```

---

## 📊 **EPOC_max Calibration Options:**

### **Option A: EPOC_max = 1,200 (Current)**

| Percentile | TSS | Strain | Band | Example |
|------------|-----|--------|------|---------|
| Median (50%) | 52 | 7.0 | Moderate | Your 2x10 |
| Q3 (75%) | 106 | 11.7 | High | Hard session |
| 90th | 181 | 13.8 | High | Weekend epic |
| 95th | 285 | 15.2 | Extreme | Long hard ride |
| 99th | 490 | 16.5 | Extreme | Pedal Wye |

### **Option B: EPOC_max = 1,000 (More sensitive)**

| Percentile | TSS | Strain | Band | Example |
|------------|-----|--------|------|---------|
| Median (50%) | 52 | 7.3 | Moderate | Your 2x10 |
| Q3 (75%) | 106 | 12.0 | High | Hard session |
| 90th | 181 | 14.2 | Extreme | Weekend epic |
| 95th | 285 | 15.7 | Extreme | Long hard ride |
| 99th | 490 | 17.0 | Extreme | Pedal Wye |

### **Option C: EPOC_max = 1,500 (More conservative)**

| Percentile | TSS | Strain | Band | Example |
|------------|-----|--------|------|---------|
| Median (50%) | 52 | 6.6 | Moderate | Your 2x10 |
| Q3 (75%) | 106 | 11.2 | High | Hard session |
| 90th | 181 | 13.3 | High | Weekend epic |
| 95th | 285 | 14.6 | Extreme | Long hard ride |
| 99th | 490 | 15.9 | Extreme | Pedal Wye |

---

## 🎯 **MY RECOMMENDATION:**

### **EPOC_max = 1,200 + Adjusted Bands:**

```swift
case 0..<5.5: return .low          // Recovery/Easy (0-40 TSS)
case 5.5..<8.5: return .moderate   // Normal training (40-80 TSS)
case 8.5..<12.0: return .hard      // Hard sessions (80-150 TSS)  
case 12.0..<14.5: return .veryHard // Weekend epics (150-250 TSS)
default: return .extreme           // Ultra rides (250+ TSS)
```

**This gives you:**

| Your Ride | TSS | Strain | Band |
|-----------|-----|--------|------|
| Easy cycling | 10 | 2.3 | Low ✅ |
| 2 x 10 (median) | 52 | 7.0 | Moderate ✅ |
| Hollins blast (Q3) | 122 | 12.3 | Very Hard ✅ |
| Afternoon epic | 193 | 14.0 | Very Hard ✅ |
| Lunch ride | 285 | 15.2 | EXTREME ✅ |
| Pedal Wye (99th) | 490 | 16.5 | EXTREME ✅ |

---

## ✅ **Summary:**

**Your training distribution:**
- **50% of rides:** TSS < 52 (Easy/Moderate)
- **25% of rides:** TSS 52-106 (Moderate/Hard)
- **15% of rides:** TSS 106-181 (Hard/Very Hard)
- **10% of rides:** TSS 181+ (Very Hard/Extreme)

**Recommended calibration:**
- EPOC_max = **1,200**
- Adjusted band thresholds to match your actual usage
- Extreme band starts at 14.5 (captures top 5% of your rides)

**What do you think?**
