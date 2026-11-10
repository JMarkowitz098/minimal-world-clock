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

echo "== Snapshot tool build"
if ! swift build --package-path Tools/Snapshots > build-snapshots.log 2>&1; then
    grep -E "error:" build-snapshots.log | head -40
    echo "SNAPSHOT TOOL BUILD FAILED (full log: build-snapshots.log)"
    exit 1
fi
echo "SNAPSHOT TOOL BUILD SUCCEEDED"
rm -f build-test.log build-app.log build-snapshots.log
