# iCloud Sync Setup Guide

This document outlines the steps required to enable iCloud sync for VeloReady.

## Overview

VeloReady now supports automatic iCloud synchronization for:
- **User Settings**: Sleep targets, training zones, display preferences
- **Strength Exercise Data**: RPE ratings and muscle group selections
- **Workout Metadata**: Exercise tracking and recovery data
- **Daily Scores**: Recovery, sleep, and strain scores (via Core Data + CloudKit)

## Xcode Project Configuration

### 1. Enable iCloud Capability

1. Open `VeloReady.xcodeproj` in Xcode
2. Select the **VeloReady** target
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability** button
5. Add **iCloud**
6. In the iCloud section, enable:
   - ☑️ **CloudKit**
   - ☑️ **Key-value storage**

### 2. Configure CloudKit Container

1. In the iCloud capability section, ensure the CloudKit container is set to:
   ```
   iCloud.com.markboulton.VeloReady2
   ```
   
2. If the container doesn't exist, click the **+** button to create it
3. Ensure the container identifier matches the one in `PersistenceController.swift`:
   ```swift
   containerIdentifier: "iCloud.com.markboulton.VeloReady2"
   ```

### 3. Entitlements File

Xcode should automatically create/update the entitlements file. Verify it contains:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.markboulton.VeloReady2</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
```

### 4. App ID Configuration (Apple Developer Portal)

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your App ID (`com.markboulton.VeloReady2`)
4. Edit the App ID and enable:
   - ☑️ **iCloud**
   - ☑️ **CloudKit** (with default container)
5. Save changes
6. Regenerate provisioning profiles if needed

### 5. CloudKit Dashboard Setup

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select your container: `iCloud.com.markboulton.VeloReady2`
3. The Core Data entities will be automatically created by CloudKit
4. No manual schema setup is required - Core Data handles this automatically

## Implementation Details

### Core Data + CloudKit Sync

The app uses `NSPersistentCloudKitContainer` for automatic Core Data synchronization:

```swift
// PersistenceController.swift
container = NSPersistentCloudKitContainer(name: "VeloReady")
description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.markboulton.VeloReady2"
)
```

**Synced Core Data Entities:**
- `DailyScores`
- `DailyPhysio`
- `DailyLoad`
- `WorkoutMetadata`

### Key-Value Storage Sync

The app uses `NSUbiquitousKeyValueStore` for lightweight data synchronization:

```swift
// iCloudSyncService.swift
NSUbiquitousKeyValueStore.default
```

**Synced Key-Value Data:**
- User settings (JSON encoded)
- RPE data (workout UUID → RPE value)
- Muscle group data (workout UUID → muscle groups array)
- Workout metadata sync data

### Automatic Sync Triggers

Automatic sync is triggered on:
1. **RPE Updates**: When user logs strength exercise RPE
2. **Settings Changes**: When user modifies any settings
3. **App Launch**: Initial sync check
4. **External Changes**: When iCloud data changes on another device

## Testing iCloud Sync

### Development Testing

1. **Enable iCloud in Simulator/Device:**
   - Settings → [Your Name] → iCloud
   - Sign in with Apple ID
   - Enable iCloud Drive

2. **Test Automatic Sync:**
   - Make changes to settings
   - Log strength exercise RPE
   - Check console for sync messages: `☁️ Successfully synced to iCloud`

3. **Test Multi-Device Sync:**
   - Install on two devices/simulators with same Apple ID
   - Make changes on Device A
   - Wait ~30 seconds
   - Verify changes appear on Device B

4. **Test Manual Restore:**
   - Go to Settings → iCloud Sync
   - Tap "Restore from iCloud"
   - Verify data is restored

### Production Testing

1. **TestFlight Testing:**
   - Ensure CloudKit production environment is configured
   - Test with real Apple IDs
   - Verify sync across multiple devices

2. **Monitor CloudKit Console:**
   - Check CloudKit Dashboard for sync activity
   - Monitor for errors or quota issues

## Troubleshooting

### iCloud Not Available

**Symptoms:** "iCloud is not available" message in settings

**Solutions:**
1. Verify user is signed into iCloud on device
2. Check iCloud Drive is enabled in device settings
3. Verify app has iCloud capability enabled in Xcode
4. Check entitlements file is correct

### Sync Not Working

**Symptoms:** Data not syncing between devices

**Solutions:**
1. Check console logs for CloudKit errors
2. Verify both devices are signed into same Apple ID
3. Ensure both devices have internet connectivity
4. Try manual sync from Settings → iCloud Sync → Sync Now
5. Check CloudKit Dashboard for container status

### CloudKit Quota Exceeded

**Symptoms:** Sync error about storage quota

**Solutions:**
1. iCloud provides generous free tier (1GB storage, 10GB transfer/day)
2. For most users, this is sufficient
3. If exceeded, user needs to upgrade iCloud storage plan
4. Consider implementing data pruning for old records

### Core Data Sync Conflicts

**Symptoms:** Data inconsistencies between devices

**Solutions:**
1. App uses `NSMergeByPropertyObjectTrumpMergePolicy`
2. Most recent changes win in conflicts
3. CloudKit handles conflict resolution automatically
4. For critical data, consider implementing custom merge logic

## Privacy & Security

- All data is encrypted in transit and at rest
- Data is stored in user's private iCloud account
- App cannot access other users' data
- User can disable iCloud sync in device settings
- Deleting app removes local data; iCloud data persists

## Storage Limits

### Key-Value Storage
- **Limit:** 1 MB total per app
- **Usage:** ~50-100 KB for typical user
- **Data:** Settings, RPE values, muscle groups

### CloudKit Storage
- **Free Tier:** 1 GB storage, 10 GB transfer/day
- **Usage:** ~1-5 MB per user per year
- **Data:** Core Data entities (scores, metadata)

## Future Enhancements

Potential improvements for iCloud sync:

1. **Conflict Resolution UI**: Show users when conflicts occur
2. **Selective Sync**: Allow users to choose what to sync
3. **Sync Status Indicator**: Real-time sync status in UI
4. **Offline Queue**: Queue changes when offline, sync when online
5. **Data Export**: Export iCloud data to file
6. **Family Sharing**: Share workout data with family members

## Support

If users experience iCloud sync issues:

1. Check device iCloud settings
2. Try manual restore from Settings → iCloud Sync
3. Restart app
4. Sign out and back into iCloud
5. Contact support with CloudKit error logs

## References

- [Apple CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [NSUbiquitousKeyValueStore](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore)
- [Core Data + CloudKit Guide](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
