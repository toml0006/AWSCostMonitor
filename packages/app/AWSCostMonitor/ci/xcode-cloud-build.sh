#!/bin/bash
# Xcode Cloud post-clone script
# This script runs after the repository is cloned but before the build starts

echo "Setting up Xcode Cloud build environment..."

# Ensure the correct development team is set
export DEVELOPMENT_TEAM="TJSYWP4C3D"

# Set automatic code signing
export CODE_SIGN_STYLE="Automatic"

echo "Build environment configured successfully"