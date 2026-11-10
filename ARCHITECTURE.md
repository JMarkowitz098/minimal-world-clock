# Architecture

How the code fits together and where things live. Rules are in [CLAUDE.md](CLAUDE.md); milestones are in [ROADMAP.md](ROADMAP.md).

## Layers

```
Apps/Mac (thin shell)    ──uses──▶  WorldClockUI  ──uses──▶  WorldClockCore
Apps/Widget (from M5)               view models,             zones, search, time math,
                                    shared views             settings (Foundation only)
```

Dependencies only point right. An iOS app would sit beside `Apps/Mac` and use the same modules.

## File map

| Need to change… | File |
|---|---|
| App entry point, windows | `Apps/Mac/WorldClockMacApp.swift` |
| App sandbox entitlements | `Apps/Mac/WorldClock.entitlements` |
| Targets, bundle IDs, versions, Info.plist keys | `project.yml` |
| Package targets | `Packages/WorldClockKit/Package.swift` |
| Placeholder window content (replaced in M3) | `WorldClockUI/PlaceholderView.swift` |
| Work handed from one session to the next (e.g. draft tests) | `docs/handoff/` (see ROADMAP.md → Handoff) |

Update this table as milestones add files.

## Invariants

- `WorldClockCore` builds with Foundation alone.
- No package resources (the App Store export doesn't re-sign SwiftPM resource bundles). Images go in each app's asset catalog.

## Recipes

**Add a source file to the package:** create it under `Packages/WorldClockKit/Sources/<Module>/`. SwiftPM picks it up; no project regeneration needed.

**Add a file to the app target:** create it under `Apps/Mac/`, then run `xcodegen generate`.
