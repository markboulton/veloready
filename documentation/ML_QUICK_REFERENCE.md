# VeloReady ML: Quick Reference Card

**Last Updated:** October 30, 2025

---

## 📊 Current Status (One Line)

**21/30 days collected → Train model Nov 8 → Ship predictions Nov 22 → Add LLM coaching Mar 2026**

---

## ✅ What's Working

- ✅ Data collection (21 days, automatic)
- ✅ Feature engineering (38 features)
- ✅ Training pipeline (coded, ready)
- ✅ Infrastructure complete

---

## ⏳ What's Next

| Date | Action | Time |
|------|--------|------|
| Oct 31 - Nov 7 | Wait (data collects automatically) | 0 hours |
| Nov 8 | Train model on Mac | 1-2 hours |
| Nov 11-15 | Build prediction service | 2-3 days |
| Nov 18-22 | Deploy to production | 2-3 days |
| Jan-Apr 2026 | Add MLX + LLM features | 3-4 months |

---

## 🎯 The Plan (One Sentence Each)

1. **Phase 2 (Nov):** Ship recovery predictions with Create ML (fast, low risk)
2. **Phase 3 (Mar):** Add AI coaching chatbot with MLX LLM (game changer)
3. **Phase 3+ (Apr):** Add real-time predictions (competitive moat)

---

## 🚀 Why Hybrid Approach?

| Framework | Best For | When |
|-----------|----------|------|
| Create ML | Tabular regression (recovery scores) | Phase 2 (Nov 2025) |
| MLX | LLM coaching, real-time, custom models | Phase 3+ (Jan 2026+) |

**Both together = Fast to market + Advanced features**

---

## 📋 Nov 8 Training Checklist

```
□ Open VeloReady on Mac
□ Settings → Debug → ML Infrastructure  
□ Verify: "Training Data: 30 days"
□ Tap: "Test Training Pipeline"
□ Wait: ~60 seconds
□ Check: "✅ Pipeline test PASSED"
□ Verify: "Current Model: 1.0"
```

**Expected:** MAE < 10, RMSE < 12, R² > 0.6

---

## 🎁 Features You'll Get

### Nov 2025: Personalized Predictions
- Tomorrow's recovery predicted today
- "✨ Personalized" badge in UI
- 5-10 points more accurate

### Mar 2026: AI Coaching Chatbot
- Ask: "Should I do intervals today?"
- Get: Personalized expert advice
- 100% on-device (private)

### Apr 2026: Real-Time Predictions
- During workout: "Hold 250W for 12 more minutes"
- Updates every 5 seconds
- Optimal pacing guidance

---

## 🔑 Key Numbers

| Metric | Current | Target |
|--------|---------|--------|
| Days Collected | 21 | 30 |
| Days Remaining | 9 | 0 |
| Features | 38 | 38 ✅ |
| Data Quality | ~85% | >80% ✅ |
| Target MAE | - | <10 points |
| Target R² | - | >0.6 |

---

## 📚 Documentation Guide

| Document | Purpose | When to Read |
|----------|---------|--------------|
| ML_EXECUTIVE_SUMMARY.md | Overview & decision | Read first |
| ML_MLX_VS_CREATEML_DECISION.md | Framework comparison | Before starting |
| ML_REVISED_IMPLEMENTATION_PLAN.md | Technical details | When implementing |
| ML_QUICK_REFERENCE.md | Quick lookup | You are here ✅ |
| ML_NEXT_STEPS.md | Step-by-step guide | Daily reference |
| ML_VISUAL_STATUS.md | Progress dashboard | Check progress |

---

## ⚡ Quick Commands

### Check ML Status
```
App → Settings → Debug → ML Infrastructure
```

### Train Model (Nov 8)
```
Debug → Test Training Pipeline → Wait 60s
```

### View Logs
```
Xcode → Console → Filter: "[ML]"
```

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| "No training data" | Wait for 30 days (currently 21) |
| "Create ML not available" | Must run on macOS (not iOS) |
| "Pipeline test failed" | Check logs, may need more data |
| "Model accuracy poor" | Normal for first model, improves with more data |

---

## 📞 Support

**Documentation:** `/Users/mark.boulton/Documents/dev/veloready/documentation/`

**Code:**
- Training: `VeloReady/Core/ML/Training/`
- Services: `VeloReady/Core/ML/Services/`
- Debug UI: `VeloReady/Features/Debug/Views/MLDebugView.swift`

---

## ✨ Success Indicators

**Phase 2 Success:**
- ✅ Model trained (MAE < 10)
- ✅ Predictions in production
- ✅ 60%+ users keep ML enabled
- ✅ No performance issues

**Phase 3 Success:**
- ✅ LLM coaching working
- ✅ Users ask questions weekly
- ✅ Response time < 5 seconds
- ✅ NPS > 8/10

---

## 🎯 One-Page Summary

```
┌─────────────────────────────────────────────────┐
│         VeloReady ML Strategy                   │
├─────────────────────────────────────────────────┤
│                                                  │
│  NOW: Collecting data (21/30 days)              │
│       ↓                                          │
│  NOV 8: Train Create ML model (1-2 hrs)        │
│       ↓                                          │
│  NOV 22: Ship predictions (2-3 weeks dev)       │
│       ↓                                          │
│  MAR 2026: Add MLX LLM coaching (3-4 months)    │
│       ↓                                          │
│  APR 2026: Real-time predictions                │
│                                                  │
│  RESULT: Best AI fitness app 🚀                 │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

**Next Action:** Wait 9 days, then train model on Nov 8! 🎯

