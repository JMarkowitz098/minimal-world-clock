#!/bin/bash
# Builds a Release copy of Minimal World Clock and installs it to /Applications, replacing any
# old copy, then restarts the widget extension so the desktop widget runs the new code.
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="Minimal World Clock"
WIDGET="MinimalWorldClockWidget"
xcodegen generate --quiet
mkdir -p build
# A failed build stops here, so an older Release copy is never installed in its place.
if ! xcodebuild -project WorldClock.xcodeproj -scheme WorldClockMac -configuration Release \
    -destination "generic/platform=macOS" -derivedDataPath build build > build/install.log 2>&1; then
    grep -E "error:" build/install.log >&2 || tail -20 build/install.log >&2
    echo "Build failed (full log: build/install.log)" >&2
    exit 1
fi
APP="build/Build/Products/Release/$NAME.app"

pkill -x "$NAME" || true
# Wait for the old copy to exit; opening while it shuts down fails with error -600.
while pgrep -x "$NAME" > /dev/null; do sleep 0.2; done
rm -rf "/Applications/$NAME.app"
cp -R "$APP" /Applications/

# Only /Applications' widget should be registered (Xcode registers the build copies too), and
# the running extension keeps the old code until it exits; macOS relaunches it when needed.
for config in Debug Release; do
    appex="build/Build/Products/$config/$NAME.app/Contents/PlugIns/$WIDGET.appex"
    [ -d "$appex" ] && pluginkit -r "$appex" 2>/dev/null || true
done
pkill -x "$WIDGET" || true

# Right after copying, macOS may not have registered the new app yet (error -600); retry briefly.
for _ in 1 2 3 4 5; do
    open "/Applications/$NAME.app" 2>/dev/null && break
    sleep 1
done
echo "Installed /Applications/$NAME.app ($(defaults read "/Applications/$NAME.app/Contents/Info.plist" CFBundleShortVersionString))"
