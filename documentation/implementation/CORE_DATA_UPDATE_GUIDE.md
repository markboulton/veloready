# Core Data Model Update Guide - MLTrainingData Entity

## CRITICAL: Manual Step Required

The Core Data model (`.xcdatamodeld`) cannot be updated programmatically. You must add the new entity using Xcode's visual editor.

---

## Step-by-Step Instructions

### 1. Open Core Data Model

1. In Xcode, navigate to: `VeloReady/Core/Data/VeloReady.xcdatamodeld`
2. Click to open the visual editor
3. You should see existing entities: `DailyScores`, `DailyPhysio`, `DailyLoad`, `WorkoutMetadata`

### 2. Add New Entity

1. Click the **"Add Entity"** button (bottom left, + icon)
2. Name it exactly: `MLTrainingData`
3. Set the entity class to: `MLTrainingData`
4. Set the module to: `VeloReady`

### 3. Add Attributes (16 total)

Click **"Add Attribute"** for each of these:

#### Identifiers
| Name | Type | Optional | Default |
|------|------|----------|---------|
| `id` | UUID | ☑️ Yes | - |
| `date` | Date | ☑️ Yes | - |

#### Feature Data
| Name | Type | Optional | Default |
|------|------|----------|---------|
| `featureVectorData` | Binary Data | ☑️ Yes | - |

#### Target Values (Predictions)
| Name | Type | Optional | Default |
|------|------|----------|---------|
| `targetRecoveryScore` | Double | ☐ No | 0 |
| `targetReadinessScore` | Double | ☐ No | 0 |

#### Actual Values (Validation)
| Name | Type | Optional | Default |
|------|------|----------|---------|
| `actualRecoveryScore` | Double | ☐ No | 0 |
| `actualReadinessScore` | Double | ☐ No | 0 |

#### Quality Metrics
| Name | Type | Optional | Default |
|------|------|----------|---------|
| `predictionError` | Double | ☐ No | 0 |
| `predictionConfidence` | Double | ☐ No | 0 |
| `dataQualityScore` | Double | ☐ No | 0 |
| `isValidTrainingData` | Boolean | ☐ No | NO |

#### Model Metadata
| Name | Type | Optional | Default |
|------|------|----------|---------|
| `modelVersion` | String | ☑️ Yes | - |
| `trainingPhase` | String | ☑️ Yes | - |

#### Timestamps
| Name | Type | Optional | Default |
|------|------|----------|---------|
| `createdAt` | Date | ☑️ Yes | - |
| `lastUpdated` | Date | ☑️ Yes | - |

### 4. Configure Entity Settings

1. Select `MLTrainingData` entity
2. In the **Data Model Inspector** (right panel):
   - Class: `MLTrainingData`
   - Module: `VeloReady` (or leave as "Global")
   - Codegen: **Manual/None** (important - we created the files manually)

### 5. Enable CloudKit Sync (Should be automatic)

The entity will automatically sync via CloudKit because:
- PersistenceController uses `NSPersistentCloudKitContainer`
- Container identifier: `iCloud.com.markboulton.VeloReady2`
- All entities in the model are synced by default

**Verify:**
1. Select the entity
2. Check that it's part of the default configuration
3. No additional CloudKit configuration needed

### 6. Save the Model

1. Press **⌘S** to save
2. You should see no warnings or errors
3. Xcode may prompt to create a new model version - **select NO** (we're just adding an entity)

---

## Verification Checklist

After adding the entity, verify:

- [ ] Entity name is exactly `MLTrainingData` (case-sensitive)
- [ ] All 16 attributes are added with correct types
- [ ] Optional flags match the table above
- [ ] Codegen is set to `Manual/None`
- [ ] Model saves without errors (⌘S)
- [ ] Build succeeds (⌘B)

---

## Common Issues

### Issue: "No such entity 'MLTrainingData'"
**Solution:** Entity name must exactly match the class name in code

### Issue: Build fails with "Use of undeclared type"
**Solution:** Ensure Codegen is set to `Manual/None`, not `Class Definition`

### Issue: "Entity is not in the model"
**Solution:** Clean build folder (⌘⇧K) and rebuild

### Issue: CloudKit sync not working
**Solution:** Verify `NSPersistentCloudKitContainer` is used in PersistenceController (already configured)

---

## After Adding Entity

Once the entity is added in Xcode:

### 1. Clean Build
```bash
⌘⇧K  # Clean build folder
⌘B   # Build
```

### 2. Run App
```bash
⌘R   # Run on simulator or device
```

### 3. Test ML Infrastructure
1. Navigate to: **Settings → Debug Settings → ML Infrastructure**
2. Tap **"Process Historical Data (90 days)"**
3. Wait for processing to complete (~10-30 seconds)
4. Verify:
   - Training Data shows number of days
   - Data quality report appears
   - No errors in console

### 4. Verify Core Data
1. While app is running, in Xcode:
   - **Debug → View Debugging → Show Core Data**
2. Look for `MLTrainingData` entity
3. Should see records for each processed day

---

## Visual Reference

### Before (Existing Entities)
```
VeloReady.xcdatamodeld
├── DailyScores
├── DailyPhysio
├── DailyLoad
└── WorkoutMetadata
```

### After (With ML Entity)
```
VeloReady.xcdatamodeld
├── DailyScores
├── DailyPhysio
├── DailyLoad
├── WorkoutMetadata
└── MLTrainingData  ← NEW
```

---

## Alternative: Import Entity Definition

If you prefer to import from a file:

1. Create `MLTrainingData.xcdatamodel` XML file
2. Use Xcode's import feature
3. **Not recommended** - manual addition is simpler and less error-prone

---

## Need Help?

If you encounter issues:

1. Check Xcode console for error messages
2. Verify all attribute names match exactly (case-sensitive)
3. Try cleaning build folder (⌘⇧K)
4. Restart Xcode if needed
5. Check that PersistenceController loads without errors

---

## Once Complete

You're ready to:
1. ✅ Build and test
2. ✅ Process historical data
3. ✅ Verify data quality
4. ✅ Commit Phase 1
5. ✅ Move to Phase 2 (baseline models)

**Estimated time: 5-10 minutes**
