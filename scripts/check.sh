#!/bin/bash
# Pre-commit check: all package tests, then a Debug build of the macOS app.
# Prints only failures and a summary line per step.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Tests"
if ! swift test --package-path Packages/WorldClockKit > build-test.log 2>&1; then
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
rm -f build-test.log build-app.log
