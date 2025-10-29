# Xcode Build Configuration Guide

## Build Errors Overview

You're encountering provisioning profile and code signing issues because the project uses advanced iOS capabilities that require proper configuration in the Apple Developer portal.

## Issue 1: Program License Agreement

**Error:** "Unable to process request - PLA Update available"

**Solution:**
1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Sign in with your Apple ID
3. Accept the latest Program License Agreement
4. This is required before any provisioning can work

## Issue 2: Provisioning Profiles & Capabilities

The project requires these capabilities:
- HealthKit
- App Groups  
- iCloud/CloudKit
- Associated Domains
- Push Notifications

### Quick Fix for Local Development (Current Setup)

I've simplified the entitlements files to include only the essential capabilities:
- **HealthKit** - Required for core functionality
- **App Groups** - Required for sharing data between app and widget

The following have been temporarily removed for local development:
- iCloud/CloudKit
- Associated Domains  
- Push Notifications

### Building the Project

**For Simulator (Recommended for Development):**

1. Open the project in Xcode
2. Select a Simulator as your target device (e.g., "iPhone 16 Pro")
3. Ensure Code Sign Style is set to "Automatic"
4. Build and run (⌘R)

The simulator doesn't require device provisioning and should work with the simplified entitlements.

**For Physical Device:**

If you need to test on a physical device, you'll need to:

1. **Accept the PLA** (see Issue 1 above)

2. **Configure App Groups:**
   - Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/)
   - Select "Identifiers"
   - Find or create identifier for `com.markboulton.VeloReady2`
   - Enable "App Groups" capability
   - Configure the group: `group.com.markboulton.VeloReady`
   - Repeat for widget: `com.markboulton.VeloReady2.RideReadyWidget`

3. **Configure HealthKit:**
   - In the same Identifiers section
   - Enable "HealthKit" for `com.markboulton.VeloReady2`

4. **Update Provisioning:**
   - In Xcode, go to Project Settings → Signing & Capabilities
   - Select your team under "Development Team"
   - Xcode will automatically create/update provisioning profiles

## Issue 3: Team Configuration

Current team ID in project: `C79WM3NZ27`

If this is not your team:
1. Open project settings in Xcode
2. Select each target (VeloReady, RideReadyWidgetExtension)
3. Under "Signing & Capabilities" tab
4. Change "Team" to your Apple Developer team

## Restoring Full Capabilities

When you're ready to add back the advanced features:

### iCloud/CloudKit
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

Configure in Developer Portal:
- Enable iCloud capability
- Create iCloud container: `iCloud.com.markboulton.VeloReady2`

### Associated Domains
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:veloready.app</string>
    <string>applinks:api.veloready.app</string>
</array>
```

Configure in Developer Portal:
- Enable Associated Domains capability
- Set up apple-app-site-association file on your domains

### Push Notifications
```xml
<key>aps-environment</key>
<string>development</string>
```

Configure in Developer Portal:
- Enable Push Notifications capability
- Create APNs certificates if needed

## Troubleshooting

### "Provisioning profile doesn't support capability"
- Ensure capability is enabled in Developer Portal
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Restart Xcode
- Try "Download Manual Profiles" in Xcode Preferences → Accounts

### "Automatic signing failed"
- Switch to Manual signing temporarily
- Download profiles from Developer Portal
- Switch back to Automatic

### Clean Build
If you continue having issues:
```bash
# Clean build folder
⌘ + Shift + K in Xcode

# Or from command line:
cd /Users/mark.boulton/Documents/dev/veloready
xcodebuild clean -project VeloReady.xcodeproj -scheme VeloReady
```

## Current Project Configuration

**Bundle Identifiers:**
- Main App: `com.markboulton.VeloReady2`
- Widget: `com.markboulton.VeloReady2.RideReadyWidget`

**App Group:**
- `group.com.markboulton.VeloReady`

**Deployment Targets:**
- Main App: iOS 18.6
- Widget: iOS 18.2

## Next Steps

1. ✅ Simplified entitlements applied
2. ⏳ Accept Apple Developer PLA
3. ⏳ Build for Simulator (should work now)
4. ⏳ Configure capabilities in Developer Portal (for device testing)
5. ⏳ Re-enable advanced features when needed

## Testing Priorities

For initial development, you can test most functionality in the Simulator with the current simplified setup:
- ✅ HealthKit (Simulator has mock health data)
- ✅ App Groups (works in Simulator)
- ❌ Push Notifications (requires device)
- ❌ Associated Domains (requires device + domain setup)
- ❌ iCloud sync (works in Simulator but limited)

