# Remote Configuration

This directory contains the remote configuration files for AWSCostMonitor App Store builds.

## Files

- `production-config.json` - The production configuration deployed to your CDN/server
- `staging-config.json` - Staging configuration for testing (optional)

## Deployment

1. Upload `production-config.json` to your web server or CDN
2. Update the `remoteConfigURL` in `RemoteConfig.swift` to point to your deployed config
3. The app will automatically fetch the latest configuration on startup

## Configuration Options

### Core Settings
- `trialDurationDays`: Length of free trial (days)
- `promoCodesEnabled`: Whether App Store promo codes are active
- `minimumVersion`: Minimum app version required (for forced updates)

### Feature Flags
- `teamCache`: Enable/disable team cache functionality
- `unlimitedProfiles`: Enable unlimited AWS profiles
- `advancedForecasting`: Advanced cost forecasting features
- `dataExport`: Data export functionality

### Marketing
- `showTrialExtension`: Show trial extension offers
- `campaignMessage`: Special promotional message
- `specialOfferActive`: Whether special pricing is active

### Endpoints
- `supportUrl`: Customer support contact
- `documentationUrl`: Help documentation link
- `whatsNewUrl`: Release notes/what's new page

## Security Notes

- This configuration is downloaded over HTTPS
- No sensitive data should be included in these files
- The app validates configuration structure before applying changes
- Invalid configurations fall back to built-in defaults

## Testing Changes

Before deploying to production:

1. Test configuration changes with a staging URL
2. Verify the app gracefully handles malformed JSON
3. Check that feature flags properly enable/disable functionality
4. Confirm trial duration changes are applied correctly

## Configuration History

Keep track of configuration changes for debugging:
- Document what changed and when
- Test impact on existing users
- Monitor app behavior after configuration updates