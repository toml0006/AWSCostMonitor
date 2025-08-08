#!/bin/bash

# AWSCostMonitor Code Signing Script
# This script signs and optionally notarizes the app for distribution

set -e

# Configuration
APP_PATH="packages/app/AWSCostMonitor/build/Release/AWSCostMonitor.app"
ENTITLEMENTS_PATH="packages/app/AWSCostMonitor/AWSCostMonitor/AWSCostMonitor.entitlements"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔐 AWSCostMonitor Code Signing Tool"
echo "===================================="

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ App not found at $APP_PATH${NC}"
    echo "Please build the app first with: npm run build:app"
    exit 1
fi

# Find signing identity
echo -e "\n${YELLOW}Finding Developer ID...${NC}"
IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F'"' '{print $2}')

if [ -z "$IDENTITY" ]; then
    echo -e "${RED}❌ No Developer ID Application certificate found${NC}"
    echo "Please install your Developer ID certificate from Apple Developer portal"
    exit 1
fi

echo -e "${GREEN}✓ Found: $IDENTITY${NC}"

# Sign the app
echo -e "\n${YELLOW}Signing app...${NC}"
codesign --force --deep \
    --sign "$IDENTITY" \
    --options runtime \
    --timestamp \
    --entitlements "$ENTITLEMENTS_PATH" \
    "$APP_PATH"

# Verify signature
echo -e "\n${YELLOW}Verifying signature...${NC}"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ App signed successfully!${NC}"
else
    echo -e "${RED}❌ Signature verification failed${NC}"
    exit 1
fi

# Check signature details
echo -e "\n${YELLOW}Signature details:${NC}"
codesign --display --verbose=4 "$APP_PATH"

# Optional: Notarization
echo -e "\n${YELLOW}Do you want to notarize the app? (y/n)${NC}"
read -r NOTARIZE

if [ "$NOTARIZE" = "y" ]; then
    echo -e "\n${YELLOW}Preparing for notarization...${NC}"
    
    # Create zip for notarization
    ZIP_PATH="AWSCostMonitor-signed.zip"
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    echo -e "${GREEN}✓ Created $ZIP_PATH${NC}"
    
    echo -e "\n${YELLOW}Enter your Apple ID:${NC}"
    read -r APPLE_ID
    
    echo -e "${YELLOW}Enter your Team ID (found in Apple Developer portal):${NC}"
    read -r TEAM_ID
    
    echo -e "${YELLOW}Enter your app-specific password:${NC}"
    read -s APP_PASSWORD
    echo
    
    echo -e "\n${YELLOW}Submitting for notarization...${NC}"
    xcrun notarytool submit "$ZIP_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$APP_PASSWORD" \
        --wait
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Notarization successful!${NC}"
        
        echo -e "\n${YELLOW}Stapling notarization ticket...${NC}"
        xcrun stapler staple "$APP_PATH"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Notarization ticket stapled!${NC}"
        else
            echo -e "${RED}❌ Failed to staple ticket${NC}"
        fi
        
        # Clean up
        rm "$ZIP_PATH"
    else
        echo -e "${RED}❌ Notarization failed${NC}"
        exit 1
    fi
fi

echo -e "\n${GREEN}🎉 Done! Your app is ready for distribution.${NC}"
echo -e "The signed app is at: ${YELLOW}$APP_PATH${NC}"

# Create DMG for distribution
echo -e "\n${YELLOW}Do you want to create a DMG for distribution? (y/n)${NC}"
read -r CREATE_DMG

if [ "$CREATE_DMG" = "y" ]; then
    DMG_NAME="AWSCostMonitor-signed.dmg"
    
    echo -e "\n${YELLOW}Creating DMG...${NC}"
    
    # Create temporary directory for DMG
    TEMP_DIR=$(mktemp -d)
    cp -R "$APP_PATH" "$TEMP_DIR/"
    ln -s /Applications "$TEMP_DIR/Applications"
    
    # Create DMG
    hdiutil create -volname "AWS Cost Monitor" \
        -srcfolder "$TEMP_DIR" \
        -ov -format UDZO \
        "$DMG_NAME"
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}✓ Created $DMG_NAME${NC}"
    
    # Sign the DMG
    echo -e "\n${YELLOW}Signing DMG...${NC}"
    codesign --sign "$IDENTITY" "$DMG_NAME"
    
    echo -e "${GREEN}✓ DMG signed and ready for distribution!${NC}"
    echo -e "Distribution file: ${YELLOW}$DMG_NAME${NC}"
fi