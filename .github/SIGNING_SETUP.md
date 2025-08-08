# Code Signing Setup for AWSCostMonitor

This guide explains how to set up code signing for AWSCostMonitor releases.

## Prerequisites

- Apple Developer ID ($99/year from developer.apple.com)
- Developer ID Application certificate
- macOS with Xcode installed

## Local Signing

Use the provided script to sign the app locally:

```bash
# Build the app first
npm run build:app

# Sign the app
./sign-app.sh
```

The script will:
1. Find your Developer ID certificate
2. Sign the app with hardened runtime
3. Optionally notarize the app
4. Create a DMG for distribution

## GitHub Actions Setup

To enable automatic signing in GitHub Actions, you need to set up the following secrets:

### 1. Export Your Certificate

```bash
# Find your certificate
security find-identity -v -p codesigning

# Export to P12 file (you'll be prompted for a password)
security export -k ~/Library/Keychains/login.keychain-db \
  -t identities \
  -f pkcs12 \
  -o certificates.p12
```

### 2. Create GitHub Secrets

Go to your repository Settings → Secrets and variables → Actions, and add:

1. **CERTIFICATES_P12**
   ```bash
   # Convert P12 to base64
   base64 -i certificates.p12 | pbcopy
   ```
   Paste the base64 string as the secret value

2. **CERTIFICATES_P12_PASSWORD**
   - The password you used when exporting the P12 file

3. **TEAM_ID**
   - Your Apple Developer Team ID (found in Apple Developer portal)
   - Format: `XXXXXXXXXX` (10 characters)

4. **APPLE_ID** (for notarization)
   - Your Apple ID email address

5. **APP_PASSWORD** (for notarization)
   - Generate at appleid.apple.com → Sign-In and Security → App-Specific Passwords
   - Create a new password for "AWSCostMonitor Notarization"

### 3. Test the Setup

Push a new tag to trigger a release:

```bash
git tag v1.2.2
git push origin v1.2.2
```

## Manual Signing Commands

If you prefer manual signing:

```bash
# Sign the app
codesign --force --deep \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  --options runtime \
  --timestamp \
  --entitlements packages/app/AWSCostMonitor/AWSCostMonitor/AWSCostMonitor.entitlements \
  /path/to/AWSCostMonitor.app

# Verify signature
codesign --verify --deep --strict --verbose=2 /path/to/AWSCostMonitor.app

# Create zip for notarization
ditto -c -k --keepParent AWSCostMonitor.app AWSCostMonitor.zip

# Submit for notarization
xcrun notarytool submit AWSCostMonitor.zip \
  --apple-id your-email@example.com \
  --team-id TEAMID \
  --password app-specific-password \
  --wait

# Staple the ticket
xcrun stapler staple AWSCostMonitor.app

# Create DMG
hdiutil create -volname "AWS Cost Monitor" \
  -srcfolder /path/to/folder/with/app \
  -ov -format UDZO \
  AWSCostMonitor.dmg

# Sign the DMG
codesign --sign "Developer ID Application: Your Name (TEAMID)" AWSCostMonitor.dmg
```

## Troubleshooting

### Certificate Not Found
```bash
# List all certificates
security find-identity -v

# If missing, download from Apple Developer portal
```

### Notarization Failed
- Check that all frameworks are signed
- Ensure hardened runtime is enabled
- Verify entitlements are correct
- Check console logs: `xcrun notarytool log`

### Users Still See Warning
- Ensure notarization completed successfully
- Verify the stapler ticket is attached
- Check that DMG is also signed

## Security Notes

- Never commit certificates or passwords to the repository
- Rotate app-specific passwords regularly
- Use GitHub environment protection rules for production releases
- Keep your Developer ID certificate secure

## Clean Up

After exporting certificates:
```bash
# Securely delete the P12 file
rm -P certificates.p12
```