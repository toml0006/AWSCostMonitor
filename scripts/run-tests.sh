#!/usr/bin/env bash
#
# Run AWSCostMonitorTests without a GUI session.
#
# WHY NOT `xcodebuild test`:
#   The test host is the app itself, a menu bar agent (LSUIElement). macOS
#   refuses to launch it from a non-GUI context and xcodebuild fails with
#   "LaunchServices has returned error -10699 … Launch prevented due to
#   'prevent launch' assertion". That is an environment failure, not a red test.
#
# WHAT THIS DOES INSTEAD:
#   `xcrun xctest` loads the test bundle directly and never asks LaunchServices
#   to launch anything. Two fixups are needed:
#     1. The bundle links @rpath/AWSCostMonitor.debug.dylib, which lives inside
#        the .app — symlinked into PackageFrameworks/ where dyld probes.
#     2. Under xctest the main bundle is the xctest binary, not an app bundle,
#        so any code reaching UNUserNotificationCenter throws
#        NSInternalInconsistencyException "bundleProxyForCurrentProcess is nil".
#        That kills the whole process, so each test class runs in its OWN
#        process and a crash is reported as BLOCKED rather than taking the
#        entire run down with it.
#
# THREE OUTCOMES, deliberately distinct — a blocked class is NOT a passing one:
#   PASS    — ran, all assertions held
#   FAIL    — ran, assertions failed
#   BLOCKED — could not run headlessly (needs a real app bundle identity).
#             Verify these by running the suite in Xcode from a GUI session.
#
# Usage:
#   scripts/run-tests.sh                     # every class, one process each
#   scripts/run-tests.sh PopoverGeometryTests
#   scripts/run-tests.sh PopoverGeometryTests/testDesiredThatFitsIsReturnedUnchanged
#
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../packages/app/AWSCostMonitor" && pwd)"
TESTS_DIR="$PROJECT_DIR/AWSCostMonitorTests"
DERIVED="$PROJECT_DIR/.build-tests"

cd "$PROJECT_DIR"

xcodebuild build-for-testing \
  -project AWSCostMonitor.xcodeproj \
  -scheme AWSCostMonitor \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" \
  -quiet || { echo "BUILD FAILED"; exit 1; }

PRODUCTS="$DERIVED/Build/Products/Debug"
BUNDLE="$PRODUCTS/AWSCostMonitor.app/Contents/PlugIns/AWSCostMonitorTests.xctest"

mkdir -p "$PRODUCTS/PackageFrameworks"
ln -sf "$PRODUCTS/AWSCostMonitor.app/Contents/MacOS/AWSCostMonitor.debug.dylib" \
       "$PRODUCTS/PackageFrameworks/AWSCostMonitor.debug.dylib"

# Explicit filter: run it alone and surface xctest's output verbatim.
if [ $# -gt 0 ]; then
  exec xcrun xctest -XCTest "$1" "$BUNDLE"
fi

# Both declaration forms — `class X: XCTestCase` and `final class X: XCTestCase`.
# A narrow pattern here silently drops classes and reports the remainder as a
# clean pass, which is worse than failing.
CLASSES=$(grep -rhoE 'class [A-Za-z0-9_]+ *: *XCTestCase' "$TESTS_DIR" \
          | sed -E 's/.*class ([A-Za-z0-9_]+) *: *XCTestCase/\1/' | sort -u)

# This project also uses swift-testing (`struct` suites with @Test). `xcrun
# xctest` cannot run those at all — it only knows XCTest. Enumerate them so the
# gap is stated rather than invisible.
SWIFT_TESTING=$(grep -rlE '^\s*@Test|import Testing' "$TESTS_DIR" 2>/dev/null \
                | xargs -I{} basename {} .swift | sort -u)

pass_total=0; fail_total=0
passed=(); failed=(); blocked=()

for cls in $CLASSES; do
  out=$(xcrun xctest -XCTest "$cls" "$BUNDLE" 2>&1)
  line=$(printf '%s\n' "$out" | grep -E "^\s+Executed [0-9]+ test" | tail -1)

  if [ -z "$line" ]; then
    reason=$(printf '%s\n' "$out" | grep -oE "reason: '[^']*'" | head -1)
    blocked+=("$cls ${reason:-(no result emitted)}")
    printf 'BLOCKED  %-32s %s\n' "$cls" "${reason:-}"
    continue
  fi

  n=$(printf '%s' "$line" | grep -oE 'Executed [0-9]+' | grep -oE '[0-9]+')
  f=$(printf '%s' "$line" | grep -oE 'with [0-9]+ failure' | grep -oE '[0-9]+')
  pass_total=$((pass_total + n - f)); fail_total=$((fail_total + f))

  if [ "$f" -eq 0 ]; then
    passed+=("$cls"); printf 'PASS     %-32s %s tests\n' "$cls" "$n"
  else
    failed+=("$cls"); printf 'FAIL     %-32s %s of %s failed\n' "$cls" "$f" "$n"
    printf '%s\n' "$out" | grep -E "error:" | head -10 | sed 's/^/         /'
  fi
done

echo
echo "─────────────────────────────────────────────"
echo "XCTest: $pass_total passed, $fail_total failed"
echo "classes: ${#passed[@]} pass, ${#failed[@]} fail, ${#blocked[@]} blocked"
if [ ${#blocked[@]} -gt 0 ]; then
  echo
  echo "BLOCKED — could not run headlessly, NOT verified:"
  printf '  - %s\n' "${blocked[@]}"
fi
if [ -n "$SWIFT_TESTING" ]; then
  echo
  echo "NOT RUN — swift-testing suites. xcrun xctest only runs XCTest, so these"
  echo "are outside this script's reach entirely and are NOT verified here:"
  printf '  - %s\n' $SWIFT_TESTING
fi
if [ ${#blocked[@]} -gt 0 ] || [ -n "$SWIFT_TESTING" ]; then
  echo
  echo "This run does NOT cover the whole suite. Before merging, run the full"
  echo "suite in Xcode from a GUI session (Cmd-U)."
fi
[ "$fail_total" -eq 0 ] || exit 1
