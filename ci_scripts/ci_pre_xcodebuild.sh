#!/bin/sh

# ci_pre_xcodebuild.sh
# Xcode Cloud pre-build script
# This script runs before Xcode Cloud starts the build

set -e

echo "🏗️ Xcode Cloud Pre-Build Script"
echo "================================"

# Ensure we're building the App Store version
if [ "${CI_XCODE_SCHEME}" != "AWSCostMonitor" ]; then
    echo "⚠️  Warning: Expected scheme 'AWSCostMonitor' but got '${CI_XCODE_SCHEME}'"
    echo "   Please ensure Xcode Cloud is configured to use the App Store scheme"
fi

# Check that we're NOT using the OPENSOURCE flag
if echo "${OTHER_SWIFT_FLAGS}" | grep -q "OPENSOURCE"; then
    echo "❌ Error: OPENSOURCE flag detected!"
    echo "   Xcode Cloud builds should use the paid App Store configuration"
    exit 1
fi

# Verify StoreKit configuration is present
STOREKIT_CONFIG="packages/app/AWSCostMonitor/Configuration.storekit"
if [ -f "${STOREKIT_CONFIG}" ]; then
    echo "✅ StoreKit configuration found"
else
    echo "⚠️  Warning: StoreKit configuration not found at ${STOREKIT_CONFIG}"
fi

echo "📦 Build Information:"
echo "  Branch: ${CI_BRANCH}"
echo "  Commit: ${CI_COMMIT}"
echo "  Build Number: ${CI_BUILD_NUMBER}"
echo "  Bundle Version: ${CI_BUNDLE_VERSION}"

# Set up for App Store build
echo "🏪 Configuring for App Store build with in-app purchases..."

# Export build settings
export PRODUCT_NAME="AWSCostMonitor"
export ENABLE_IAP="YES"
export TEAM_CACHE_REQUIRES_PURCHASE="YES"

echo "✅ Pre-build configuration complete"
echo "   Building with Team Cache as paid feature ($3.99)"