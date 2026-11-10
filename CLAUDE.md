# Minimal World Clock

A minimal macOS world clock: a Clock window, a Compare window for two time zones, and a desktop widget. Headed for the App Store.

- [ARCHITECTURE.md](ARCHITECTURE.md): file map, layers, invariants, recipes (read before non-trivial changes)
- [ROADMAP.md](ROADMAP.md): milestones and their acceptance tests
- [design_doc.md](design_doc.md): requirements and product decisions

## Commands

| Task | Command |
|---|---|
| **Pre-commit check** (all tests + app build; prints only failures) | `./scripts/check.sh` |
| Tests only (fast, use for TDD) | `swift test --package-path Packages/WorldClockKit` |
| Regenerate Xcode project (after editing `project.yml` or adding/removing app files) | `xcodegen generate` |
| Build Debug app | `xcodebuild -project WorldClock.xcodeproj -scheme WorldClockMac -configuration Debug -derivedDataPath build build` |
| Run Debug app | `open "build/Build/Products/Debug/Minimal World Clock.app"` |
| Quit it | `pkill -x "Minimal World Clock"` |

`WorldClock.xcodeproj` and `Apps/*/Info.plist` are generated: never hand-edit them; change `project.yml` instead.

## Rules

- **WorldClockCore imports Foundation only.** No SwiftUI, AppKit, WidgetKit, or AppIntents. Side effects (persistence) are protocols defined in Core and implemented outside it or with Foundation.
- **Time is injected.** Core never calls `Date()`; time-dependent functions take `at now: Date`. Tests use fixed instants, never the Mac's own time zone (`TimeZone.current`).
- **App and widget targets stay thin.** Anything shareable goes in WorldClockKit.
- **Views are small reusable pieces** that read display-ready values from a view model.
- **Saved data stays backward compatible:** decoding is lenient and falls back to defaults.
- **Accessible by default:** every control has a VoiceOver label; color is never the only signal; respect Reduce Motion.

## Workflow

- **TDD** for Core and view models: failing test first, then make it pass, then refactor. Views are checked by running the app; ask the user to check visual changes.
- **One milestone from ROADMAP.md at a time. Stop after each one and check in with the user before starting the next.** The milestone's listed tests are its acceptance criteria.
- **Each milestone runs in a fresh chat.** Start by reading ROADMAP.md → Handoff. Before the final commit of a session, rewrite that Handoff section: what was done, exactly what's next, open questions for the user, and anything learned that isn't obvious from the code (gotchas, decisions, dead ends). Also update ARCHITECTURE.md's file map and record product decisions in design_doc.md. Nothing may live only in the chat or a scratchpad: work in progress goes in the repo (e.g. `docs/handoff/`).
- Swift 6 language mode; fix concurrency warnings rather than suppressing them.
- After a structural change, update ARCHITECTURE.md in the same commit.

## Git

- Run `./scripts/check.sh` before every commit. Never commit failing tests or a broken build.
- Commit after every milestone (`M<n>: <title>` plus a short body) and check it off in ROADMAP.md in the same commit. Other work gets a descriptive title.
- Push after every commit once the GitHub remote exists.
- Work on `main` unless told otherwise.
