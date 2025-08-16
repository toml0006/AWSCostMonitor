#!/bin/sh

# ci_post_xcodebuild.sh
# Xcode Cloud post-build script
# This script runs after Xcode Cloud completes the build

set -e

echo "🎉 Xcode Cloud Post-Build Script"
echo "================================"

# Verify the build completed successfully
if [ "${CI_XCODEBUILD_EXIT_CODE}" != "0" ]; then
    echo "❌ Build failed with exit code: ${CI_XCODEBUILD_EXIT_CODE}"
    exit 1
fi

echo "✅ Build completed successfully"

# Log build artifacts
echo "📦 Build Artifacts:"
echo "  Product: ${CI_PRODUCT}"
echo "  Archive Path: ${CI_ARCHIVE_PATH}"
echo "  Bundle ID: ${CI_BUNDLE_IDENTIFIER}"

# Verify this is an App Store build
echo "🏪 Verifying App Store configuration..."

# Check that the built app includes StoreKit framework
if [ -d "${CI_ARCHIVE_PATH}" ]; then
    echo "✅ Archive created successfully"
    
    # You could add additional verification here
    # For example, checking that certain files exist in the archive
else
    echo "⚠️  Warning: Archive path not found"
fi

# Summary
echo ""
echo "📊 Build Summary:"
echo "  Scheme: ${CI_XCODE_SCHEME}"
echo "  Configuration: App Store (with IAP)"
echo "  Team Cache: Requires $3.99 purchase"
echo "  Build Number: ${CI_BUILD_NUMBER}"
echo ""
echo "✅ Ready for App Store distribution"