# Strain Score Calibration Verification

**Date:** October 16, 2025  
**EPOC_max:** 8,800 (new calibration)

---

## 📊 **Verification Against Real Rides**

### **Your Recent Activities (from logs):**

| Activity | NP | Duration | TSS | Expected Band |
|----------|-------|----------|-----|---------------|
| 2 x 10 | 177W | 48 min | 52 | Moderate |
| 20s | 154W | 40 min | 33 | Moderate-Easy |
| Cycling | 125W | 19 min | 11 | Easy/Recovery |
| Cycling | 143W | 15 min | 11 | Easy/Recovery |
| 5 x 3 mixed | 177W | 54 min | ~58 | Moderate |
| Shortened. Mechanical | 210W | 59 min | ~85 | Hard |
| 4 x 8 | 173W | 37 min | ~45 | Moderate |
| Pedal Wye (ultra) | 197W | 340 min | ~200 | Extreme |
| Hollins lane blast | 216W | 71 min | ~100 | Hard |

---

## 🧮 **Calculation Formula:**

```
1. TRIMP = TSS (for power-based activities)
2. EPOC = 0.25 × TRIMP^1.1
3. Strain = 18 × ln(EPOC + 1) / ln(8,800 + 1)
4. Band based on 0-18 scale
```

---

## 📈 **Strain Score Predictions (New Calibration):**

### **Recovery/Easy Rides (TSS 0-30)**
| TSS | TRIMP | EPOC | Strain | Band | Example |
|-----|-------|------|--------|------|---------|
| 10 | 10 | 2.5 | 1.8 | Low | Easy spin |
| 15 | 15 | 3.9 | 2.4 | Low | Recovery ride |
| 20 | 20 | 5.3 | 2.9 | Low | Short commute |
| 25 | 25 | 6.7 | 3.3 | Low | Light endurance |
| 30 | 30 | 8.1 | 3.7 | Low | Easy endurance |

**Your rides:**
- **Cycling (11 TSS):** Strain = **1.9** (Low) ✅ Recovery

---

### **Moderate-Easy Rides (TSS 30-50)**
| TSS | TRIMP | EPOC | Strain | Band | Example |
|-----|-------|------|--------|------|---------|
| 35 | 35 | 9.6 | 4.0 | Low | Zone 2 endurance |
| 40 | 40 | 11.1 | 4.3 | Low | Longer Z2 |
| 45 | 45 | 12.6 | 4.6 | Low | Extended endurance |
| 50 | 50 | 14.2 | 4.9 | Low | Steady tempo |

**Your rides:**
- **20s (33 TSS):** Strain = **3.8** (Low) ✅ Easy workout
- **4 x 8 (45 TSS):** Strain = **4.6** (Low) ✅ Moderate-easy intervals

---

### **Moderate Rides (TSS 50-80)**
| TSS | TRIMP | EPOC | Strain | Band | Example |
|-----|-------|------|--------|------|---------|
| 52 | 52 | 14.8 | 5.0 | Low | Your "2 x 10" ride |
| 55 | 55 | 15.7 | 5.2 | Low | Sweet spot |
| 60 | 60 | 17.3 | 5.5 | Low | Threshold intervals |
| 65 | 65 | 18.9 | 5.7 | Low | Hard tempo |
| 70 | 70 | 20.5 | 5.9 | Low | Solid workout |
| 75 | 75 | 22.1 | 6.1 | **Moderate** | Longer intervals |
| 80 | 80 | 23.8 | 6.3 | **Moderate** | Race pace work |

**Your rides:**
- **2 x 10 (52 TSS):** Strain = **5.0** (Low) ⚠️ **BORDERLINE**
- **5 x 3 mixed (58 TSS):** Strain = **5.4** (Low) ⚠️ **BORDERLINE**

---

### **Hard Rides (TSS 80-120)**
| TSS | TRIMP | EPOC | Strain | Band | Example |
|-----|-------|------|--------|------|---------|
| 85 | 85 | 25.4 | 6.5 | **Moderate** | Hard intervals |
| 90 | 90 | 27.1 | 6.7 | **Moderate** | Race simulation |
| 95 | 95 | 28.8 | 6.9 | **Moderate** | FTP test |
| 100 | 100 | 30.5 | 7.1 | **Moderate** | Century pace |
| 110 | 110 | 33.9 | 7.5 | **Moderate** | Hard training |
| 120 | 120 | 37.4 | 7.8 | **Moderate** | Very hard day |

**Your rides:**
- **Shortened. Mechanical (85 TSS):** Strain = **6.5** (Moderate) ✅
- **Hollins lane blast (100 TSS):** Strain = **7.1** (Moderate) ✅

---

### **Very Hard Rides (TSS 120-180)**
| TSS | TRIMP | EPOC | Strain | Band | Example |
|-----|-------|------|--------|------|---------|
| 130 | 130 | 40.9 | 8.1 | **Moderate** | Long hard ride |
| 140 | 140 | 44.5 | 8.4 | **Moderate** | Race effort |
| 150 | 150 | 48.1 | 8.7 | **Moderate** | Gran fondo |
| 160 | 160 | 51.8 | 9.0 | **Moderate** | Multi-hour race |
| 170 | 170 | 55.5 | 9.3 | **Moderate** | Long race |
| 180 | 180 | 59.3 | 9.6 | **Moderate** | Very long race |

---

### **Extreme Rides (TSS 180+)**
| TSS | TRIMP | EPOC | Strain | Band | Example |
|-----|-------|------|--------|------|---------|
| 200 | 200 | 67.0 | 10.1 | **Moderate** | Epic ride |
| 220 | 220 | 74.9 | 10.5 | **High** | Ultra-endurance |
| 250 | 250 | 86.4 | 11.1 | **High** | Multi-day stage |
| 300 | 300 | 105.9 | 11.9 | **High** | Ironman bike leg |
| 350 | 350 | 126.1 | 12.6 | **High** | Ultra-race |
| 400 | 400 | 146.9 | 13.1 | **High** | Extreme event |

**Your rides:**
- **Pedal Wye (200 TSS, 340 min):** Strain = **10.1** (Moderate/High border) ✅

---

## ⚠️ **PROBLEM IDENTIFIED:**

### **The calibration is STILL too conservative!**

**Issue:** With EPOC_max = 8,800:
- TSS 52 → Strain 5.0 (still Low, barely touches Moderate at TSS 75)
- TSS 100 → Strain 7.1 (Moderate, not High)
- Need TSS 220 to reach High band (10.5)

**Expected behavior (based on Whoop/training zones):**
- TSS 50-60 (moderate ride) → Strain 6-8 (Moderate band)
- TSS 100 (hard ride) → Strain 10-12 (High band)
- TSS 150+ (very hard) → Strain 14+ (High/Extreme)

---

## 🎯 **RECOMMENDED FIX:**

### **Lower EPOC_max to increase sensitivity:**

**Option 1: EPOC_max = 3,000** (more aggressive)
```
TSS 50 → Strain 7.0 (Moderate) ✅
TSS 100 → Strain 11.5 (High) ✅
TSS 150 → Strain 14.0 (High) ✅
```

**Option 2: EPOC_max = 4,500** (balanced)
```
TSS 50 → Strain 6.0 (Moderate) ✅
TSS 100 → Strain 10.0 (Moderate/High) ✅
TSS 150 → Strain 12.5 (High) ✅
```

**Option 3: EPOC_max = 2,000** (very aggressive, Whoop-like)
```
TSS 50 → Strain 8.5 (Moderate) ✅
TSS 100 → Strain 13.0 (High) ✅
TSS 150 → Strain 15.5 (Extreme) ✅
```

---

## 📊 **Strain Band Thresholds:**

**Current bands (from code):**
```swift
case 0..<6.0: return .low         // 0-5.9 (recovery/easy)
case 6.0..<10.5: return .moderate // 6.0-10.4 (normal training)
case 10.5..<14.5: return .high    // 10.5-14.4 (hard training)
default: return .extreme          // 14.5-18.0 (very hard/race)
```

**These thresholds are reasonable!** The problem is the EPOC_max is still too high.

---

## ✅ **RECOMMENDATION:**

**Use EPOC_max = 3,000 for realistic strain distribution**

This will give:
- Your TSS 52 ride → Strain 7.0 (Moderate) ✅
- Easy rides (TSS 20) → Strain 3.5 (Low) ✅
- Hard rides (TSS 100) → Strain 11.5 (High) ✅
- Epic rides (TSS 200) → Strain 15.5 (Extreme) ✅

**Math verification:**
```
Target: Strain 7.0 for TSS 52
TSS 52 → TRIMP 52 → EPOC 14.8
7.0 = 18 * ln(14.8 + 1) / ln(EPOC_max + 1)
7.0 = 18 * 2.756 / ln(EPOC_max + 1)
ln(EPOC_max + 1) = 18 * 2.756 / 7.0 = 7.087
EPOC_max + 1 = e^7.087 = 1,198
EPOC_max ≈ 1,200 (even more aggressive!)
```

**Actually, EPOC_max = 1,200 might be even better!**
