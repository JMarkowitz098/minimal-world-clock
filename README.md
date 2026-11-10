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
- `scripts/`: setup, check, install, and release scripts; `scripts/hooks/`: git hooks
- `Tools/Snapshots/`: renders the SwiftUI views to PNG for visual checks
- `.claude/`: Claude Code settings and the `/milestone` skill
- `ROADMAP.md`: milestones. `design_doc.md`: requirements and decisions. `ARCHITECTURE.md`: how the code fits together. `CLAUDE.md`: instructions for AI agents working in the repo.

## Setup

Requires macOS 14 or later, Xcode, and XcodeGen.

```sh
brew install xcodegen
./scripts/setup.sh   # installs the pre-commit hook and generates the Xcode project
```

The pre-commit hook runs `./scripts/check.sh`, so a commit fails if tests fail, the build breaks, or the compiler warns.

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

# Render views to PNG (light + dark) in build/snapshots/
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

- **M9:** `./scripts/install.sh` installs a Release build to /Applications (needed to try the desktop widget).
- **M10:** `./scripts/release.sh` checks, bumps the build number, archives, signs, uploads to App Store Connect, and tags the release. It follows the same process as `~/Projects/pomodoro_timer`, whose README has the full App Store Connect and TestFlight steps. This section will hold this app's copy of them.
