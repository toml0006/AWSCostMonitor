#!/bin/bash

# Xcode Cloud post-clone script
# This script is automatically run by Xcode Cloud after cloning the repository

set -e

echo "Running Xcode Cloud post-clone script..."

# Print environment info for debugging
echo "Xcode version: $(xcodebuild -version)"
echo "Current directory: $(pwd)"
echo "Development team: ${CI_TEAM_ID:-Not set}"

# Ensure we're in the right directory
if [ -d "packages/app/AWSCostMonitor" ]; then
    cd packages/app/AWSCostMonitor
    echo "Changed to packages/app/AWSCostMonitor directory"
fi

# Resolve Swift Package dependencies
echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project AWSCostMonitor.xcodeproj -scheme AWSCostMonitor

echo "Post-clone script completed successfully"
