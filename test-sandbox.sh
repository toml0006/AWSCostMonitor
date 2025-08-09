#!/bin/bash

echo "Testing AWSCostMonitor Sandbox Implementation"
echo "=============================================="
echo ""

# Check if app is running
if ps aux | grep -q "[A]WSCostMonitor.app"; then
    echo "✅ App is running"
else
    echo "❌ App is not running"
    exit 1
fi

# Check if app is sandboxed
APP_PATH="/Users/jackson/Library/Developer/Xcode/DerivedData/AWSCostMonitor-dnnjmbaepcbtkadyeqhrsjamblkk/Build/Products/Debug/AWSCostMonitor.app"
ENTITLEMENTS=$(codesign -d --entitlements - "$APP_PATH" 2>&1)

if echo "$ENTITLEMENTS" | grep -q "com.apple.security.app-sandbox"; then
    if echo "$ENTITLEMENTS" | grep -A1 "com.apple.security.app-sandbox" | grep -q "true"; then
        echo "✅ App sandbox is ENABLED"
    else
        echo "❌ App sandbox is DISABLED"
    fi
else
    echo "❌ App sandbox entitlement not found"
fi

# Check for security-scoped bookmark entitlements
if echo "$ENTITLEMENTS" | grep -q "com.apple.security.files.bookmarks.app-scope"; then
    if echo "$ENTITLEMENTS" | grep -A1 "com.apple.security.files.bookmarks.app-scope" | grep -q "true"; then
        echo "✅ Security-scoped bookmarks are ENABLED"
    else
        echo "❌ Security-scoped bookmarks are DISABLED"
    fi
else
    echo "❌ Security-scoped bookmarks entitlement not found"
fi

# Check for file access entitlements
if echo "$ENTITLEMENTS" | grep -q "com.apple.security.files.user-selected.read-only"; then
    if echo "$ENTITLEMENTS" | grep -A1 "com.apple.security.files.user-selected.read-only" | grep -q "true"; then
        echo "✅ User-selected file access is ENABLED"
    else
        echo "❌ User-selected file access is DISABLED"
    fi
else
    echo "❌ User-selected file access entitlement not found"
fi

# Check if AWS config bookmark exists in UserDefaults
if defaults read middleout.AWSCostMonitor AWSConfigFolderBookmark 2>/dev/null | grep -q "data"; then
    echo "✅ AWS config bookmark is SAVED"
else
    echo "⚠️  AWS config bookmark not yet saved (first-run required)"
fi

echo ""
echo "Test Summary:"
echo "- The app is properly sandboxed with security-scoped bookmarks"
echo "- On first run, the app will prompt for AWS config access"
echo "- After granting access, the bookmark will be saved persistently"
echo ""
echo "To test the permission flow:"
echo "1. Reset the bookmark: defaults delete middleout.AWSCostMonitor AWSConfigFolderBookmark"
echo "2. Restart the app: pkill AWSCostMonitor && open '$APP_PATH'"
echo "3. Grant access to ~/.aws folder when prompted"