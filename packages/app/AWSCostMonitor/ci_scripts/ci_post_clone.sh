#!/bin/bash

# Xcode Cloud post-clone script
# This script is automatically run by Xcode Cloud after cloning the repository

set -e

echo "Running Xcode Cloud post-clone script..."

# Print environment info for debugging
echo "Xcode version: $(xcodebuild -version)"
echo "Current directory: $(pwd)"
echo "Development team: ${CI_TEAM_ID:-Not set}"
echo "Bundle ID: ${CI_BUNDLE_ID:-Not set}"
echo "Product: ${CI_PRODUCT:-Not set}"

# Check if we're in the packages structure
if [ -d "packages/app/AWSCostMonitor" ]; then
    echo "Found packages/app/AWSCostMonitor directory"
    cd packages/app/AWSCostMonitor
elif [ -f "AWSCostMonitor.xcodeproj/project.pbxproj" ]; then
    echo "Already in correct directory"
else
    echo "Warning: Could not find AWSCostMonitor.xcodeproj"
fi

# Resolve Swift Package dependencies
echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project AWSCostMonitor.xcodeproj -scheme AWSCostMonitor -derivedDataPath ~/Library/Developer/Xcode/DerivedData || true

echo "Post-clone script completed successfully"
