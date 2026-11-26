# Minimal World Clock

A minimal macOS world clock (macOS 15+): a Clock window, a Compare window for two time zones, and a desktop widget. On the Mac App Store since 2026-11-23 (1.0.0).

- [HANDOFF.md](HANDOFF.md): where things stand and what's next (**read first**)
- [ROADMAP.md](ROADMAP.md): the plan only: milestones and their parts, one line each
- [docs/milestones/](docs/milestones/): working detail for each milestone: tests, "Done when", notes on what differed from the plan
- [ARCHITECTURE.md](ARCHITECTURE.md): the code **as it is now**: file map, layers, invariants, recipes (read before non-trivial changes)
- [design_doc.md](design_doc.md): requirements and product decisions, with their reasons
- [docs/lessons.md](docs/lessons.md): API quirks, gotchas and dead ends, by topic
- [docs/manual-checks.md](docs/manual-checks.md): steps the user checks in the running app or on the desktop, and their results
- [docs/backlog.md](docs/backlog.md): known issues and unscheduled ideas
- [docs/app-store/](docs/app-store/): the store listing, screenshots and App Store Connect status

## Commands

| Task | Command |
|---|---|
| **Work on a milestone part** | `/milestone` (skill in `.claude/skills/milestone/`) |
| **Pre-commit check** (all tests + app build + team-signing and privacy-manifest check + snapshot tool build; warnings fail; prints only failures) | `./scripts/check.sh` |
| Tests only (fast, use for TDD) | `swift test --package-path Packages/WorldClockKit` |
| Regenerate Xcode project (after editing `project.yml` or adding/removing app files) | `xcodegen generate` |
| Build Debug app | `xcodebuild -project WorldClock.xcodeproj -scheme WorldClockMac -configuration Debug -derivedDataPath build build` |
| Run Debug app | `open "build/Build/Products/Debug/Minimal World Clock.app"` |
| Quit it | `pkill -x "Minimal World Clock"` |
| Try the widget (macOS only offers widgets from /Applications) | build, then `pkill -x MinimalWorldClockWidget; rm -rf "/Applications/Minimal World Clock.app" && cp -R "build/Build/Products/Debug/Minimal World Clock.app" /Applications/ && open "/Applications/Minimal World Clock.app"`; unregister the build copy with `pluginkit -r "build/Build/Products/Debug/Minimal World Clock.app/Contents/PlugIns/MinimalWorldClockWidget.appex"` and `lsregister -u "build/Build/Products/Debug/Minimal World Clock.app"` (full path in README; stray copies in LaunchServices leave widgets on the placeholder); check with `pluginkit -m -p com.apple.widgetkit-extension \| grep worldclock`. The user checks the desktop (agents can't see it). Stopping `MinimalWorldClockWidget` matters: the running extension keeps the old code otherwise. |
| **Render views to PNG** (light + dark, or light only for `lightOnly` entries, plus `-contrast` renders with Increase Contrast for `increasedContrast` entries, into `build/snapshots/`; temporary option sheets from `Prototypes.swift` go to `build/prototypes/`; both keep only current entries; then Read them) | `swift run --package-path Tools/Snapshots Snapshots [name-filter]` |
| **Upload to App Store Connect** (check → bump build → archive → upload → tag; needs a clean `main`; `--version 1.1.0` for a new version; `--local` only archives) | `./scripts/release.sh` |
| Regenerate App Store screenshots (into `docs/app-store/screenshots/`, after UI changes) | `swift run --package-path Tools/Snapshots Snapshots --app-store` |
| **Install the Release build** to /Applications (replaces the old copy, restarts the widget extension, launches it) | `./scripts/install.sh` |
| Regenerate the app icon (after editing `drawIcon()`) | `swift scripts/make-icon.swift` |
| Regenerate `ZoneNames.swift` (each zone's country and English zone names, for search) after a macOS update changes the zone list | `swift scripts/make-zone-names.swift` |
| One-time setup after cloning (git hooks + Xcode project) | `./scripts/setup.sh` |

`WorldClock.xcodeproj` and `Apps/*/Info.plist` are generated: never hand-edit them; change `project.yml` instead.

## Rules

- **WorldClockCore imports Foundation only.** No SwiftUI, AppKit, WidgetKit, or AppIntents. Side effects (persistence) are protocols defined in Core and implemented outside it or with Foundation.
- **Time is injected.** Core never calls `Date()`; time-dependent functions take `at now: Date`. Tests use fixed instants, never the Mac's own time zone (`TimeZone.current`).
- **App and widget targets stay thin.** Anything shareable goes in WorldClockKit.
- **Views are small reusable pieces** that read display-ready values from a view model. Colors come from `@Environment(\.theme)`, sizes from `TimeStyle`, hover through `.trackingHover`, and both windows sit in `ScalingWindow` (ARCHITECTURE.md → Invariants).
- **Builds are signed with the development team** (`project.yml`), never ad-hoc: macOS drops an ad-hoc widget's settings. A build step and `check.sh` enforce it; don't remove them.
- **Saved data stays backward compatible:** decoding is lenient and falls back to defaults (and the fallback is logged, see `Log`).
- **Accessible by default:** every control has a VoiceOver label; color is never the only signal (assume color-blind users); respect Reduce Motion, Increase Contrast, and Reduce Transparency.
- **Lightweight and minimal:** no third-party dependencies; no timers faster than the display needs (once a minute; the app never shows seconds); no background work while windows are hidden; no feature, option, or UI element that the requirements don't call for (the user dislikes feature-heavy clock apps).

## Workflow

- **One part at a time** from ROADMAP.md, with the `/milestone` skill. **Check in before each part:** review it with the user against what's changed since it was planned (and detail an outlined milestone before its first part); build only after the user's go-ahead. After each commit, ask whether to continue in this session or stop. HANDOFF.md is rewritten in every commit, so any new session can pick up.
- **Small parts.** One part = one commit = one idea the user can review in about 10–15 minutes. Split anything bigger in ROADMAP.md first.
- **TDD** for Core and view models: failing test first, then make it pass, then refactor.
- **Check views yourself with snapshots:** register each new or changed view in `Tools/Snapshots/Sources/Snapshots/Catalog.swift` with fixed dates and zones, render, and Read the PNGs. What snapshots can't show (window behavior, relaunch, the widget on the desktop) goes in `docs/manual-checks.md` as steps for the user.
- **Design iterations use option sheets** (`Prototypes.swift`, rendered to `build/prototypes/`), not rebuilds of the app for each round.
- **Nothing lives only in the chat or a scratchpad:** work in progress goes in the repo (e.g. `docs/handoff/`).
- Swift 6 language mode; fix concurrency warnings rather than suppressing them.
- **Docs describe the code as it is after each commit.** Every commit ticks its part in ROADMAP.md, rewrites HANDOFF.md, and updates every doc its changes affect: ARCHITECTURE.md (file map, recipes), README.md and the Commands table here, design_doc.md (product decisions), docs/lessons.md (gotchas found). Plans belong in `docs/milestones/`, not in ARCHITECTURE.md. See the `/milestone` skill for the checklist.
- **Keep ROADMAP.md and HANDOFF.md short.** ROADMAP.md is one line per part, with no tests, notes or dates. HANDOFF.md is rewritten each time, never appended (about 10 lines, no history). Detail goes in `docs/milestones/`, lessons in `docs/lessons.md`, issues and ideas in `docs/backlog.md`, and history in commit bodies.

## Git

- `./scripts/check.sh` runs automatically as a pre-commit hook (`scripts/hooks/`, installed by `scripts/setup.sh`). Never commit failing tests or a broken build, and don't bypass the hook with `--no-verify`.
- Commit after every part (`M<n>.<k>: <title>` plus a short body) and tick it in ROADMAP.md in the same commit; the last part of a milestone also marks the milestone `(done)`. Other work gets a descriptive title.
- **Push after every commit** (`git push`). Remote: `origin` → github.com/JMarkowitz098/minimal-world-clock.
- Work on `main` unless told otherwise.
