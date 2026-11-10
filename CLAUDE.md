# Minimal World Clock

A minimal macOS world clock (macOS 15+): a Clock window, a Compare window for two time zones, and a desktop widget. Headed for the App Store.

- [ARCHITECTURE.md](ARCHITECTURE.md): file map, layers, invariants, recipes (read before non-trivial changes)
- [ROADMAP.md](ROADMAP.md): milestones and their acceptance tests
- [design_doc.md](design_doc.md): requirements and product decisions

## Commands

| Task | Command |
|---|---|
| **Run a milestone end to end** | `/milestone` (skill in `.claude/skills/milestone/`) |
| **Pre-commit check** (all tests + app build + team-signing check + snapshot tool build; warnings fail; prints only failures) | `./scripts/check.sh` |
| Tests only (fast, use for TDD) | `swift test --package-path Packages/WorldClockKit` |
| Regenerate Xcode project (after editing `project.yml` or adding/removing app files) | `xcodegen generate` |
| Build Debug app | `xcodebuild -project WorldClock.xcodeproj -scheme WorldClockMac -configuration Debug -derivedDataPath build build` |
| Run Debug app | `open "build/Build/Products/Debug/Minimal World Clock.app"` |
| Quit it | `pkill -x "Minimal World Clock"` |
| Try the widget (macOS only offers widgets from /Applications) | build, then `pkill -x MinimalWorldClockWidget; rm -rf "/Applications/Minimal World Clock.app" && cp -R "build/Build/Products/Debug/Minimal World Clock.app" /Applications/ && open "/Applications/Minimal World Clock.app"`; unregister the build copy with `pluginkit -r "build/Build/Products/Debug/Minimal World Clock.app/Contents/PlugIns/MinimalWorldClockWidget.appex"`; check with `pluginkit -m -p com.apple.widgetkit-extension \| grep worldclock`. The user checks the desktop (agents can't see it). Stopping `MinimalWorldClockWidget` matters: the running extension keeps the old code otherwise. |
| **Render views to PNG** (light + dark, into `build/snapshots/`; then Read them) | `swift run --package-path Tools/Snapshots Snapshots [name-filter]` |
| One-time setup after cloning (git hooks + Xcode project) | `./scripts/setup.sh` |

`WorldClock.xcodeproj` and `Apps/*/Info.plist` are generated: never hand-edit them; change `project.yml` instead.

## Rules

- **WorldClockCore imports Foundation only.** No SwiftUI, AppKit, WidgetKit, or AppIntents. Side effects (persistence) are protocols defined in Core and implemented outside it or with Foundation.
- **Time is injected.** Core never calls `Date()`; time-dependent functions take `at now: Date`. Tests use fixed instants, never the Mac's own time zone (`TimeZone.current`).
- **App and widget targets stay thin.** Anything shareable goes in WorldClockKit.
- **Views are small reusable pieces** that read display-ready values from a view model.
- **Builds are signed with the development team** (`project.yml`), never ad-hoc: macOS drops an ad-hoc widget's settings. A build step and `check.sh` enforce it; don't remove them.
- **Saved data stays backward compatible:** decoding is lenient and falls back to defaults.
- **Accessible by default:** every control has a VoiceOver label; color is never the only signal (assume color-blind users); respect Reduce Motion, Increase Contrast, and Reduce Transparency.
- **Lightweight and minimal:** no third-party dependencies; no timers faster than the display needs (once a minute unless seconds are shown); no background work while windows are hidden; no feature, option, or UI element that the requirements don't call for (the user dislikes feature-heavy clock apps).

## Workflow

- **TDD** for Core and view models: failing test first, then make it pass, then refactor.
- **Check views yourself with snapshots:** register each new or changed view in `Tools/Snapshots/Sources/Snapshots/Catalog.swift` with fixed dates and zones, render, and Read the PNGs. Ask the user only about what snapshots can't show (window behavior, relaunch, the widget on the desktop).
- **One milestone from ROADMAP.md at a time. Stop after each one and check in with the user before starting the next.** The milestone's listed tests are its acceptance criteria.
- **Each milestone runs in a fresh chat.** Start by reading ROADMAP.md → Handoff. Before the final commit of a session, rewrite that Handoff section: what was done, exactly what's next, open questions for the user, and anything learned that isn't obvious from the code (gotchas, decisions, dead ends). Also update ARCHITECTURE.md's file map and record product decisions in design_doc.md. Nothing may live only in the chat or a scratchpad: work in progress goes in the repo (e.g. `docs/handoff/`).
- Swift 6 language mode; fix concurrency warnings rather than suppressing them.
- **Docs follow the code in the same commit.** When a change adds, moves, or removes files, commands, rules, or decisions, update the matching doc (ARCHITECTURE.md file map and recipes, README.md and the Commands table here, design_doc.md) before committing. See the `/milestone` skill for the checklist.

## Git

- `./scripts/check.sh` runs automatically as a pre-commit hook (`scripts/hooks/`, installed by `scripts/setup.sh`). Never commit failing tests or a broken build, and don't bypass the hook with `--no-verify`.
- Commit after every milestone (`M<n>: <title>` plus a short body) and check it off in ROADMAP.md in the same commit. Other work gets a descriptive title.
- **Push after every commit** (`git push`). Remote: `origin` → github.com/JMarkowitz098/minimal-world-clock.
- Work on `main` unless told otherwise.
