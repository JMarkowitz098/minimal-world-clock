#!/bin/bash
# Pre-commit check: all package tests, a Debug build of the macOS app, and a build of the
# snapshot tool. Compiler warnings fail the check. Prints only failures and a summary per step.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Tests"
if ! swift test --package-path Packages/WorldClockKit -Xswiftc -warnings-as-errors > build-test.log 2>&1; then
    grep -E "error:|✘" build-test.log | head -40
    echo "TESTS FAILED (full log: build-test.log)"
    exit 1
fi
grep -E "Test run with" build-test.log

echo "== macOS app build"
xcodegen generate --quiet
if ! xcodebuild -project WorldClock.xcodeproj -scheme WorldClockMac -configuration Debug \
    -derivedDataPath build build > build-app.log 2>&1; then
    grep -E "error:" build-app.log | head -40
    echo "BUILD FAILED (full log: build-app.log)"
    exit 1
fi
grep -E "warning: " build-app.log | grep -vi appintents || true
echo "BUILD SUCCEEDED"

# The app and widget must carry a team ID: macOS drops an ad-hoc signed widget's settings (M5).
for bundle in "build/Build/Products/Debug/Minimal World Clock.app" \
              "build/Build/Products/Debug/Minimal World Clock.app/Contents/PlugIns/MinimalWorldClockWidget.appex"; do
    team=$(codesign -dv "$bundle" 2>&1 | sed -n 's/^TeamIdentifier=//p')
    if [ -z "$team" ] || [ "$team" = "not set" ]; then
        echo "SIGNING CHECK FAILED: $(basename "$bundle") has no team ID (ad-hoc signed). See project.yml."
        exit 1
    fi
    # Each bundle needs its own privacy manifest, or App Store Connect flags the upload (M11).
    if [ ! -f "$bundle/Contents/Resources/PrivacyInfo.xcprivacy" ]; then
        echo "PRIVACY MANIFEST MISSING in $(basename "$bundle"). See Apps/*/PrivacyInfo.xcprivacy."
        exit 1
    fi
done
echo "SIGNING AND PRIVACY MANIFEST CHECK PASSED"

echo "== Snapshot tool build"
if ! swift build --package-path Tools/Snapshots > build-snapshots.log 2>&1; then
    grep -E "error:" build-snapshots.log | head -40
    echo "SNAPSHOT TOOL BUILD FAILED (full log: build-snapshots.log)"
    exit 1
fi
echo "SNAPSHOT TOOL BUILD SUCCEEDED"
rm -f build-test.log build-app.log build-snapshots.log
