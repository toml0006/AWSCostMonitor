#!/bin/sh

# ci_post_clone.sh
# Xcode Cloud post-clone script
# This script runs after Xcode Cloud clones the repository

set -e

echo "🔧 Xcode Cloud Post-Clone Script"
echo "================================"

# Print environment info
echo "📱 Build Configuration:"
echo "  Scheme: ${CI_XCODE_SCHEME}"
echo "  Configuration: ${CI_XCODEBUILD_CONFIGURATION}"
echo "  Platform: ${CI_PRODUCT_PLATFORM}"
echo "  Xcode Version: ${CI_XCODE_VERSION}"

# Ensure we're using the App Store scheme with paid features
if [ "${CI_XCODE_SCHEME}" = "AWSCostMonitor-OpenSource" ]; then
    echo "❌ Error: Wrong scheme selected!"
    echo "Please configure Xcode Cloud to use 'AWSCostMonitor' scheme (not OpenSource)"
    echo "The OpenSource scheme is only for GitHub releases"
    exit 1
fi

# Verify we're NOT building with OPENSOURCE flag
echo "✅ Using App Store scheme: ${CI_XCODE_SCHEME}"
echo "   This build will include in-app purchases"

# Set up any required environment
echo "🔄 Setting up build environment..."

# You can add additional setup here if needed
# For example, downloading additional resources, setting up credentials, etc.

echo "✅ Post-clone setup complete"