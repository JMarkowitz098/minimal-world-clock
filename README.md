# Minimal World Clock

A minimal world clock for macOS:

- **Clock window:** the current time in any time zone.
- **Compare window:** two time zones side by side, with a scrubber to answer "3 pm here is what time there?"
- **Desktop widget:** the time in a chosen zone, on your desktop.

Status: early development. See [ROADMAP.md](ROADMAP.md) for what's done and what's next.

## Layout

- `Packages/WorldClockKit/`: shared code
  - `WorldClockCore`: time zone logic, no UI
  - `WorldClockUI`: SwiftUI views and view models
- `Apps/Mac/`: macOS app entry point, kept small
- `Apps/Widget/`: desktop widget extension (embedded in the app), kept small
- `project.yml`: XcodeGen spec. Generates `WorldClock.xcodeproj`, which isn't committed.
- `scripts/`: setup and check scripts (install and release scripts come in M10 and M11); `scripts/hooks/`: git hooks
- `Tools/Snapshots/`: renders the SwiftUI views to PNG for visual checks
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

# Render views to PNG (light + dark) in build/snapshots/ (also removes renders of views no longer in the catalog)
swift run --package-path Tools/Snapshots Snapshots [name-filter]

# Open in Xcode instead
open WorldClock.xcodeproj

# Delete build output
rm -rf build Packages/WorldClockKit/.build
```

## Working with Claude Code

The repo is built one roadmap milestone per chat. Start a new chat and run `/milestone` (or say "start M1"). Claude reads ROADMAP.md → Handoff, builds the milestone test-first, checks the UI with snapshots, updates the docs and handoff, commits, pushes, and stops for you to review. Routine build and test commands are pre-approved in `.claude/settings.json`.

## Deploying

Not set up yet. These arrive with the roadmap:

- **M10:** `./scripts/install.sh` installs a Release build to /Applications (until then, copy the Debug build as in Testing locally).
- **M11:** `./scripts/release.sh` checks, bumps the build number, archives, signs, uploads to App Store Connect, and tags the release. It follows the same process as `~/Projects/pomodoro_timer`, whose README has the full App Store Connect and TestFlight steps. This section will hold this app's copy of them.
