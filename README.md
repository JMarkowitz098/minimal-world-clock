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
- `project.yml`: XcodeGen spec. Generates `WorldClock.xcodeproj`, which isn't committed.
- `scripts/`: check, install, and release scripts
- `ROADMAP.md`: milestones. `design_doc.md`: requirements and decisions. `ARCHITECTURE.md`: how the code fits together. `CLAUDE.md`: instructions for AI agents working in the repo.

## Setup

Requires macOS 14 or later, Xcode, and XcodeGen.

```sh
brew install xcodegen
xcodegen generate
```

## Testing locally

```sh
# Everything: all tests + a Debug build of the app. Run before every commit.
./scripts/check.sh

# Tests only (fast)
swift test --package-path Packages/WorldClockKit

# Build and run the app
xcodebuild -project WorldClock.xcodeproj -scheme WorldClockMac -configuration Debug -derivedDataPath build build
open "build/Build/Products/Debug/Minimal World Clock.app"

# Quit it
pkill -x "Minimal World Clock"

# Open in Xcode instead
open WorldClock.xcodeproj

# Delete build output
rm -rf build Packages/WorldClockKit/.build
```

## Deploying

Not set up yet. These arrive with the roadmap:

- **M8:** `./scripts/install.sh` installs a Release build to /Applications (needed to try the desktop widget).
- **M9:** `./scripts/release.sh` checks, bumps the build number, archives, signs, uploads to App Store Connect, and tags the release. It follows the same process as `~/Projects/pomodoro_timer`, whose README has the full App Store Connect and TestFlight steps. This section will hold this app's copy of them.
