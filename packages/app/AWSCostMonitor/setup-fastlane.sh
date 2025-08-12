#!/bin/bash

# Setup script for Fastlane
# This prepares your environment for App Store submission

echo "🚀 AWSCostMonitor Fastlane Setup"
echo "================================="
echo ""

# Check for Ruby
if ! command -v ruby &> /dev/null; then
    echo "❌ Ruby is not installed. Please install Ruby first."
    echo "   brew install ruby"
    exit 1
fi

# Check for Bundler
if ! command -v bundle &> /dev/null; then
    echo "📦 Installing Bundler..."
    gem install bundler
fi

# Install dependencies
echo "📦 Installing Fastlane and dependencies..."
bundle install

# Create .env file for credentials
if [ ! -f "fastlane/.env" ]; then
    echo "🔐 Creating fastlane/.env for credentials..."
    cat > fastlane/.env << 'EOL'
# Fastlane Environment Variables
# IMPORTANT: Do not commit this file to git!

# Your Apple ID (email)
APPLE_ID=your-apple-id@example.com

# App Store Connect Team ID (if different from dev portal)
ITC_TEAM_ID=TJSYWP4C3D

# For API key authentication (recommended over password)
# Get these from App Store Connect → Users → Keys
# APP_STORE_CONNECT_API_KEY_ID=
# APP_STORE_CONNECT_ISSUER_ID=
# APP_STORE_CONNECT_API_KEY_PATH=

# For password authentication (not recommended)
# FASTLANE_PASSWORD=
# FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=

# Optional: Match configuration for code signing
# MATCH_GIT_URL=
# MATCH_PASSWORD=

# Optional: Slack webhook for notifications
# SLACK_URL=
EOL
    echo "✅ Created fastlane/.env - Please update with your credentials"
    echo ""
fi

# Add to .gitignore
if ! grep -q "fastlane/.env" .gitignore 2>/dev/null; then
    echo "fastlane/.env" >> .gitignore
    echo "fastlane/report.xml" >> .gitignore
    echo "fastlane/Preview.html" >> .gitignore
    echo "fastlane/screenshots" >> .gitignore
    echo "fastlane/test_output" >> .gitignore
    echo "✅ Added Fastlane files to .gitignore"
fi

echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Edit fastlane/.env with your Apple ID and credentials"
echo ""
echo "2. Create an App Store Connect API key (recommended):"
echo "   - Go to https://appstoreconnect.apple.com/access/api"
echo "   - Create a new key with 'App Manager' role"
echo "   - Download the .p8 file"
echo "   - Add the key details to fastlane/.env"
echo ""
echo "3. Available Fastlane commands:"
echo ""
echo "   bundle exec fastlane mac setup              # Initial setup"
echo "   bundle exec fastlane mac bump_version       # Bump version number"
echo "   bundle exec fastlane mac screenshots        # Generate screenshots"
echo "   bundle exec fastlane mac create_app         # Create app on App Store Connect"
echo "   bundle exec fastlane mac upload_metadata    # Upload app metadata"
echo "   bundle exec fastlane mac beta              # Upload to TestFlight"
echo "   bundle exec fastlane mac release           # Full release to App Store"
echo "   bundle exec fastlane mac submit_for_review # Submit for review"
echo ""
echo "4. For your first submission:"
echo "   bundle exec fastlane mac create_app        # Create the app listing"
echo "   bundle exec fastlane mac release bump:minor # Build and upload v1.3.0"
echo ""
echo "✨ Setup complete! Edit fastlane/.env then run commands above."