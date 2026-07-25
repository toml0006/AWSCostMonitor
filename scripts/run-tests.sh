#!/usr/bin/env bash
#
# Run AWSCostMonitorTests without a GUI session.
#
# `xcodebuild test` cannot be used headlessly: the test host is the app itself,
# which is a menu bar agent (LSUIElement), and macOS refuses to launch it from a
# non-GUI context — it fails with "LaunchServices has returned error -10699 …
# Launch prevented due to 'prevent launch' assertion".
#
# `xcrun xctest` loads the bundle directly and never asks LaunchServices to
# launch anything. It needs one fixup: the bundle links @rpath/
# AWSCostMonitor.debug.dylib, which lives inside the .app, so we symlink it into
# PackageFrameworks/ — one of the paths dyld actually probes.
#
# Usage:
#   scripts/run-tests.sh                    # all test classes
#   scripts/run-tests.sh PopoverGeometryTests
#   scripts/run-tests.sh PopoverGeometryTests/testDesiredThatFitsIsReturnedUnchanged
#
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../packages/app/AWSCostMonitor" && pwd)"
DERIVED="$PROJECT_DIR/.build-tests"
FILTER="${1:-All}"

cd "$PROJECT_DIR"

xcodebuild build-for-testing \
  -project AWSCostMonitor.xcodeproj \
  -scheme AWSCostMonitor \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" \
  -quiet

PRODUCTS="$DERIVED/Build/Products/Debug"
BUNDLE="$PRODUCTS/AWSCostMonitor.app/Contents/PlugIns/AWSCostMonitorTests.xctest"

mkdir -p "$PRODUCTS/PackageFrameworks"
ln -sf "$PRODUCTS/AWSCostMonitor.app/Contents/MacOS/AWSCostMonitor.debug.dylib" \
       "$PRODUCTS/PackageFrameworks/AWSCostMonitor.debug.dylib"

exec xcrun xctest -XCTest "$FILTER" "$BUNDLE"
