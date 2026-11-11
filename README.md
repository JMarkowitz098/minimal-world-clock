# Minimal World Clock

A minimal world clock for macOS:

- **Clock window:** the current time in any time zone.
- **Compare window:** two time zones side by side, with a scrubber to answer "3 pm here is what time there?"
- **Desktop widget:** the time in a chosen zone, on your desktop.

Status: version 1.0.0, being prepared for the App Store. See [ROADMAP.md](ROADMAP.md) for what's done and what's next.

## Layout

- `Packages/WorldClockKit/`: shared code
  - `WorldClockCore`: time zone logic, no UI
  - `WorldClockUI`: SwiftUI views and view models
- `Apps/Mac/`: macOS app entry point, kept small
- `Apps/Widget/`: desktop widget extension (embedded in the app), kept small
- `project.yml`: XcodeGen spec. Generates `WorldClock.xcodeproj`, which isn't committed.
- `scripts/`: setup, check and install scripts; `make-icon.swift` (draws the app icon into `Apps/Mac/Assets.xcassets`) and `make-zone-names.swift` (regenerates the zone → country and zone-name table search uses); `release.sh` (App Store uploads, below); `scripts/hooks/`: git hooks
- `Tools/Snapshots/`: renders the SwiftUI views to PNG for visual checks, and the App Store screenshots
- `docs/app-store/`: App Store listing text and screenshots (the privacy policy and support pages live on jaredmarkowitz.com/apps/world-clock, from `~/Projects/portfolio`)
- `.claude/`: Claude Code settings and the `/milestone` skill
- `ROADMAP.md`: milestones. `design_doc.md`: requirements and decisions. `ARCHITECTURE.md`: how the code fits together. `CLAUDE.md`: instructions for AI agents working in the repo.

## Setup

Requires macOS 15 or later, Xcode, XcodeGen, and the **Apple Development certificate for team Y7W4DC22F6** in your keychain (Xcode → Settings → Accounts). Every build is signed with it: an ad-hoc signed widget appears on the desktop but forgets the zone you pick, so the build refuses to produce one ("error: The widget must be signed with a development team"). On another team, change `DEVELOPMENT_TEAM` in `project.yml`, and the App Group ID (prefixed with the team ID) in both `.entitlements` files and `WorldClockUI/AppGroup.swift`.

```sh
brew install xcodegen
./scripts/setup.sh   # installs the pre-commit hook and generates the Xcode project
```

The pre-commit hook runs `./scripts/check.sh`, so a commit fails if tests fail, the build breaks, or the compiler warns.

## Testing locally

```sh
# Everything: all tests + a Debug build of the app + a check that it's team-signed. Run before every commit.
./scripts/check.sh

# Tests only (fast)
swift test --package-path Packages/WorldClockKit

# Build and run the app
xcodebuild -project WorldClock.xcodeproj -scheme WorldClockMac -configuration Debug -derivedDataPath build build
open "build/Build/Products/Debug/Minimal World Clock.app"

# Quit it
pkill -x "Minimal World Clock"

# Try the desktop widget: macOS only offers widgets from apps in /Applications.
# Build first (above), then install the Debug build over any older copy and launch it once.
# Also stop the running widget extension: it keeps the old code until it exits.
pkill -x "Minimal World Clock"; pkill -x MinimalWorldClockWidget; rm -rf "/Applications/Minimal World Clock.app"
cp -R "build/Build/Products/Debug/Minimal World Clock.app" /Applications/
open "/Applications/Minimal World Clock.app"
pluginkit -r "build/Build/Products/Debug/Minimal World Clock.app/Contents/PlugIns/MinimalWorldClockWidget.appex"  # only /Applications' copy stays registered
pluginkit -m -p com.apple.widgetkit-extension | grep worldclock   # registered?
# Then right-click the desktop → Edit Widgets → search "Minimal World Clock".
# After a signing change, remove and re-add the widget before judging it.

# Render views to PNG (light + dark; light only where colors are fixed; some also with Increase Contrast) in build/snapshots/ (design option sheets: build/prototypes/; also removes renders no entry makes)
swift run --package-path Tools/Snapshots Snapshots [name-filter]

# Redraw the app icon (after editing drawIcon() in the script) into Apps/Mac/Assets.xcassets
swift scripts/make-icon.swift

# Regenerate the search table of zone countries and names (after a macOS update changes the zone list)
swift scripts/make-zone-names.swift

# Open in Xcode instead
open WorldClock.xcodeproj

# Delete build output
rm -rf build Packages/WorldClockKit/.build
```

## Working with Claude Code

The repo is built one roadmap milestone per chat. Start a new chat and run `/milestone` (or say "start M1"). Claude reads ROADMAP.md → Handoff, builds the milestone test-first, checks the UI with snapshots, updates the docs and handoff, commits, pushes, and stops for you to review. Routine build and test commands are pre-approved in `.claude/settings.json`.

## Deploying

```sh
# Build a Release copy (universal: Apple silicon + Intel), install it to /Applications over any
# older copy, restart the widget extension so the desktop widget runs the new code, and launch it.
./scripts/install.sh
```

### Lightweight budget

Measured on the Release build (1.0.0, 2026-11-11, macOS 27, Apple silicon) with both windows open and idle for a minute (`top -stats cpu,idlew,power`, `footprint`):

| | Measured | Budget |
|---|---|---|
| App bundle (universal, widget included) | 7.6 MB | under 10 MB |
| Idle CPU | 0.0% (0.7% for one sample at the minute tick) | near 0% |
| Energy (`top`'s power, Activity Monitor's Energy Impact) and idle wakeups | 0.0 and 0 between ticks | low |
| Memory (footprint) | app 29 MB (peak 32 MB), widget extension 13 MB | under 50 MB |
| Timers while a window is hidden | none: ticking pauses while a window is minimized, covered, on another Space or the app is hidden | none |

No third-party dependencies.

### App Store

Every release, whether for TestFlight or the App Store, starts the same way: upload a build with `./scripts/release.sh`. What happens next is done in [App Store Connect](https://appstoreconnect.apple.com). The process is the same as `~/Projects/pomodoro_timer`'s, which has shipped; its README has the longer TestFlight walkthrough.

```sh
./scripts/release.sh                  # same version, next build number
./scripts/release.sh --version 1.1.0  # new version (and next build number)
./scripts/release.sh --local          # archive only, to check archiving works (no upload, changes nothing)

# Regenerate the App Store screenshots (docs/app-store/screenshots/) after a UI change
swift run --package-path Tools/Snapshots Snapshots --app-store
```

**Versions and builds.** The version (`MARKETING_VERSION`, e.g. `1.0.0`) is what users see. The build (`CURRENT_PROJECT_VERSION`) counts uploads; every upload needs a higher one, and the script bumps it. Both are set twice in `project.yml` (app and widget) and must match: the script bumps both and refuses to run if they differ. Keep the version while testing or fixing a rejected submission; bump it (`--version`) once a version is live and you ship changes.

**One-time setup.**
1. `~/.config/appstore/credentials.env` (shared by all apps, never committed; already set up for pomodoro_timer): `TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH` (see the header of `scripts/release.sh`).
2. This Mac registered as a **macOS** device on developer.apple.com (Certificates, Identifiers & Profiles → Devices), done for pomodoro_timer on the same team.
3. The app record in App Store Connect: **Apps → + → New App**, platform macOS, name "Minimal World Clock", bundle ID `com.jaredmarkowitz.minimalworldclock`, SKU `MINIMAL-WORLD-CLOCK-MAC`. If the bundle ID isn't in the list, register it under Certificates, Identifiers & Profiles → Identifiers first (Xcode also does this on the first release).

**What the script does.** Needs a clean `main`. It runs `./scripts/check.sh`, bumps the build number, archives a universal Release build (signing automatically with the team; the App Group is team-ID prefixed, so no provisioning-profile entitlements and no separate App Store entitlements file), checks the archive (both bundles, privacy manifests, universal, matching versions), uploads, then commits `Release <version> (<build>)`, tags `v<version>-<build>` and pushes. If anything fails it reverts the bump; read `build/release.log` (archive) or `build/upload.log` (upload). The build appears under **TestFlight** after about 15 minutes.

**Submitting.** On the version page fill in the listing from `docs/app-store/listing.md`, the screenshots from `docs/app-store/screenshots/`, and pick the build. The first time, also App Information, App Privacy (**Data Not Collected**, then Publish), Pricing and Availability, and the age rating (values in the listing). Then **Add for Review** → **Submit**. Before the first submission, the privacy and support pages must be live (push `~/Projects/portfolio`). The contact phone needs international format ("+" and country code) or Save fails silently.
