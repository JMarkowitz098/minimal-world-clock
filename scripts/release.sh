#!/bin/bash
# One-command release: check → bump build number → archive → sign → upload to App Store Connect → tag.
# Modeled on ~/Projects/pomodoro_timer/scripts/release.sh, adapted to this project: two targets
# (app + widget) whose versions must match, and team signing even for --local (an ad-hoc widget
# fails the "Require team signing" build step, see project.yml).
#
# Usage:
#   ./scripts/release.sh                 # upload a new build of the current version
#   ./scripts/release.sh --version 1.1.0 # bump the marketing version too
#   ./scripts/release.sh --local         # archive with the development signing only (no upload, nothing changes)
#
# Upload needs ~/.config/appstore/credentials.env (shared by all apps, never committed):
#   TEAM_ID=XXXXXXXXXX            # developer.apple.com → Membership
#   ASC_KEY_ID=XXXXXXXXXX         # App Store Connect → Users and Access → Integrations → API key
#   ASC_ISSUER_ID=xxxxxxxx-...    # same page
#   ASC_KEY_PATH=~/.config/appstore/AuthKey_XXXXXXXXXX.p8
set -euo pipefail
cd "$(dirname "$0")/.."

LOCAL=false
NEW_VERSION=""
while [ $# -gt 0 ]; do
    case "$1" in
        --local) LOCAL=true ;;
        --version) NEW_VERSION="${2:?--version needs a value, e.g. 1.1.0}"; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

ARCHIVE=build/Release.xcarchive
EXPORT_DIR=build/export
APP="$ARCHIVE/Products/Applications/Minimal World Clock.app"
WIDGET="$APP/Contents/PlugIns/MinimalWorldClockWidget.appex"

archive() {
    xcodegen generate --quiet
    rm -rf "$ARCHIVE"
    # The generic destination makes a universal (Apple silicon + Intel) app; the Mac App Store
    # doesn't thin, so this is what users download.
    xcodebuild -project WorldClock.xcodeproj -scheme WorldClockMac -configuration Release \
        -destination "generic/platform=macOS" -archivePath "$ARCHIVE" "$@" archive > build/release.log 2>&1 \
        || { grep -E "error:" build/release.log | head -20; echo "ARCHIVE FAILED (log: build/release.log)"; return 1; }
    verify_archive
    echo "Archived $ARCHIVE ($(plist_value "$APP" CFBundleShortVersionString) build $(plist_value "$APP" CFBundleVersion))"
}

plist_value() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/Info.plist"; }

# What App Store Connect would reject later, checked now: both bundles present, universal,
# with a privacy manifest, and with matching versions.
verify_archive() {
    local bundle
    for bundle in "$APP" "$WIDGET"; do
        [ -d "$bundle" ] || { echo "Missing $bundle in the archive" >&2; return 1; }
        [ -f "$bundle/Contents/Resources/PrivacyInfo.xcprivacy" ] \
            || { echo "No privacy manifest in $(basename "$bundle")" >&2; return 1; }
    done
    local archs
    archs=$(lipo -archs "$APP/Contents/MacOS/Minimal World Clock")
    [[ "$archs" == *arm64* && "$archs" == *x86_64* ]] || { echo "Not universal: $archs" >&2; return 1; }
    for key in CFBundleShortVersionString CFBundleVersion; do
        [ "$(plist_value "$APP" $key)" = "$(plist_value "$WIDGET" $key)" ] \
            || { echo "App and widget $key differ" >&2; return 1; }
    done
}

mkdir -p build
if $LOCAL; then
    archive
    exit 0
fi

# --- Preconditions -----------------------------------------------------------
CREDS=~/.config/appstore/credentials.env
[ -f "$CREDS" ] || { echo "Missing $CREDS (see header of this script)" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CREDS"
ASC_KEY_PATH="${ASC_KEY_PATH/#\~/$HOME}"
for var in TEAM_ID ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH; do
    [ -n "${!var:-}" ] || { echo "$var not set in $CREDS" >&2; exit 1; }
done
[ -z "$(git status --porcelain)" ] || { echo "Commit or stash changes first." >&2; exit 1; }
[ "$(git branch --show-current)" = main ] || { echo "Release from main." >&2; exit 1; }

./scripts/check.sh

# --- Bump versions (reverted if anything below fails) ------------------------
# project.yml sets both versions once per target (app and widget); they must stay equal.
current() { sed -nE "s/.*$1: \"([^\"]+)\".*/\1/p" project.yml | sort -u; }
[ "$(current CURRENT_PROJECT_VERSION | wc -l)" -eq 1 ] && [ "$(current MARKETING_VERSION | wc -l)" -eq 1 ] \
    || { echo "The app's and widget's versions differ in project.yml; make them equal first." >&2; exit 1; }
trap 'git checkout -- project.yml; echo "Release failed; version bump reverted."' ERR
BUILD=$(( $(current CURRENT_PROJECT_VERSION) + 1 ))
sed -i '' -E "s/(CURRENT_PROJECT_VERSION: )\"[0-9]+\"/\1\"$BUILD\"/" project.yml
if [ -n "$NEW_VERSION" ]; then
    sed -i '' -E "s/(MARKETING_VERSION: )\"[^\"]+\"/\1\"$NEW_VERSION\"/" project.yml
fi
VERSION=$(current MARKETING_VERSION)
echo "== Releasing $VERSION ($BUILD)"

# --- Archive, sign, upload ---------------------------------------------------
AUTH=(-allowProvisioningUpdates
      -authenticationKeyPath "$ASC_KEY_PATH"
      -authenticationKeyID "$ASC_KEY_ID"
      -authenticationKeyIssuerID "$ASC_ISSUER_ID")

# Same entitlements as local builds: the App Group is team-ID prefixed, which needs no
# provisioning profile, so there's no separate App Store entitlements file.
archive CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" DEVELOPMENT_TEAM="$TEAM_ID" "${AUTH[@]}"

OPTIONS=build/ExportOptions.plist
cat > "$OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>upload</string>
    <key>teamID</key><string>$TEAM_ID</string>
    <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
PLIST

rm -rf "$EXPORT_DIR"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$OPTIONS" "${AUTH[@]}" > build/upload.log 2>&1 \
    || { grep -E "error" build/upload.log | head -20; echo "UPLOAD FAILED (log: build/upload.log)"; false; }
echo "Uploaded to App Store Connect. It appears under TestFlight after processing (~15 min)."

# --- Record the release ------------------------------------------------------
trap - ERR
git add project.yml
git commit -q -m "Release $VERSION ($BUILD)"
git tag "v$VERSION-$BUILD"
git push -q && git push -q --tags
echo "Tagged v$VERSION-$BUILD and pushed."
