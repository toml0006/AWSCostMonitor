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

# Navigate to the project directory
# We're starting in /Volumes/workspace/repository/packages/app/AWSCostMonitor/ci_scripts
cd ..
if [ -f "AWSCostMonitor.xcodeproj/project.pbxproj" ]; then
    echo "Found AWSCostMonitor.xcodeproj in $(pwd)"
else
    echo "Warning: Could not find AWSCostMonitor.xcodeproj in $(pwd)"
    ls -la
fi

# Resolve Swift Package dependencies
echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project AWSCostMonitor.xcodeproj -scheme AWSCostMonitor -derivedDataPath ~/Library/Developer/Xcode/DerivedData || true

echo "Post-clone script completed successfully"
