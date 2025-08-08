#!/bin/bash

# Generate PNG icons from SVG for macOS app and website
# Requires: librsvg (brew install librsvg)

echo "Generating icons from logo-simple.svg..."

# Create output directories
mkdir -p packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset
mkdir -p packages/website/public

# macOS App Icon sizes (for Assets.xcassets)
# Size scale 1x
rsvg-convert -w 16 -h 16 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_16x16.png
rsvg-convert -w 32 -h 32 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_32x32.png
rsvg-convert -w 128 -h 128 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_128x128.png
rsvg-convert -w 256 -h 256 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_256x256.png
rsvg-convert -w 512 -h 512 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_512x512.png

# Size scale 2x
rsvg-convert -w 32 -h 32 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png
rsvg-convert -w 64 -h 64 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png
rsvg-convert -w 256 -h 256 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png
rsvg-convert -w 512 -h 512 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png
rsvg-convert -w 1024 -h 1024 logo-simple.svg -o packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png

# Website favicon and logo
rsvg-convert -w 32 -h 32 logo-simple.svg -o packages/website/public/favicon.ico
rsvg-convert -w 192 -h 192 logo-simple.svg -o packages/website/public/logo192.png
rsvg-convert -w 512 -h 512 logo-simple.svg -o packages/website/public/logo512.png
rsvg-convert -w 256 -h 256 logo-simple.svg -o packages/website/public/logo.png

# Copy SVG files to website
cp logo.svg packages/website/public/logo-memphis.svg
cp logo-simple.svg packages/website/public/logo-simple.svg

echo "Icon generation complete!"
echo ""
echo "Generated files:"
echo "- macOS app icons in packages/app/AWSCostMonitor/AWSCostMonitor/Assets.xcassets/AppIcon.appiconset/"
echo "- Website favicon and logos in packages/website/public/"
echo ""
echo "Note: You may need to update the Contents.json file in the AppIcon.appiconset folder to reference the new icons."