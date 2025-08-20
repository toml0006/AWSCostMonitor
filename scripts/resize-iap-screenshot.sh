#!/bin/bash

# Script to resize IAP screenshot to App Store Connect requirements
# Usage: ./resize-iap-screenshot.sh input.png output.png

if [ $# -lt 1 ]; then
    echo "Usage: $0 <input_image> [output_image]"
    echo "Example: $0 screenshot.png team-cache-iap-screenshot.png"
    exit 1
fi

INPUT="$1"
OUTPUT="${2:-team-cache-iap-screenshot.png}"

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file '$INPUT' not found"
    exit 1
fi

# Get current dimensions
DIMENSIONS=$(sips -g pixelWidth -g pixelHeight "$INPUT" 2>/dev/null | grep pixel | awk '{print $2}')
WIDTH=$(echo "$DIMENSIONS" | head -1)
HEIGHT=$(echo "$DIMENSIONS" | tail -1)

echo "Current dimensions: ${WIDTH}x${HEIGHT}"

# Check if image is already 1024x1024
if [ "$WIDTH" = "1024" ] && [ "$HEIGHT" = "1024" ]; then
    echo "Image is already 1024x1024 pixels!"
    cp "$INPUT" "$OUTPUT"
    echo "Copied to: $OUTPUT"
    exit 0
fi

# Method 1: Crop to square (center crop)
if [ "$WIDTH" -ge 1024 ] && [ "$HEIGHT" -ge 1024 ]; then
    echo "Cropping to 1024x1024 square from center..."
    # Calculate center crop
    X_OFFSET=$(( ($WIDTH - 1024) / 2 ))
    Y_OFFSET=$(( ($HEIGHT - 1024) / 2 ))
    
    # Use sips to crop
    sips -c 1024 1024 --cropOffset $X_OFFSET $Y_OFFSET "$INPUT" --out "$OUTPUT"
    echo "✅ Created square IAP screenshot: $OUTPUT"
    
# Method 2: Resize to fit 1024x1024 (may distort)
else
    echo "Resizing to 1024x1024..."
    echo "Warning: Image will be stretched to square format"
    
    # Create a square version
    sips -z 1024 1024 "$INPUT" --out "$OUTPUT"
    echo "✅ Created square IAP screenshot: $OUTPUT"
    echo ""
    echo "Note: Image may appear distorted. Consider taking a new screenshot"
    echo "with a more square window layout for better results."
fi

# Verify the output
if [ -f "$OUTPUT" ]; then
    NEW_DIMENSIONS=$(sips -g pixelWidth -g pixelHeight "$OUTPUT" 2>/dev/null | grep pixel | awk '{print $2}')
    NEW_WIDTH=$(echo "$NEW_DIMENSIONS" | head -1)
    NEW_HEIGHT=$(echo "$NEW_DIMENSIONS" | tail -1)
    
    echo ""
    echo "Final dimensions: ${NEW_WIDTH}x${NEW_HEIGHT}"
    
    if [ "$NEW_WIDTH" = "1024" ] && [ "$NEW_HEIGHT" = "1024" ]; then
        echo "✅ Success! Screenshot is ready for App Store Connect"
        echo ""
        echo "Next steps:"
        echo "1. Go to App Store Connect"
        echo "2. Navigate to In-App Purchases → Team Cache"
        echo "3. Upload '$OUTPUT' in the Screenshot section"
    else
        echo "⚠️ Warning: Final dimensions are not 1024x1024"
    fi
fi