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
| Time zone value (validation, city/region names, Codable) | `WorldClockCore/Zone.swift` |
| Zone list and search (matching, ranking) | `WorldClockCore/ZoneCatalog.swift` |
| Wall-clock time at an instant, and wall time → instant (DST gaps and overlaps) | `WorldClockCore/WallTime.swift` |
| UTC offset text (`UTC+5:30`) and difference between zones (`−3 h 30 min`, `Same time`) | `WorldClockCore/Offsets.swift` |
| Yesterday / today / tomorrow relative to another zone | `WorldClockCore/DayRelation.swift` |
| Fixed test instants and helpers (`jan15Noon`, `mar15Noon`, `utc(…)`, `wall(…)`, `zone(…)`) | `Tests/WorldClockCoreTests/TestSupport.swift` |
| Placeholder window content (replaced in M3) | `WorldClockUI/PlaceholderView.swift` |
| Views rendered for visual checks (and later App Store screenshots) | `Tools/Snapshots/Sources/Snapshots/Catalog.swift` |
| What the pre-commit check runs | `scripts/check.sh` (hook: `scripts/hooks/pre-commit`) |
| Commands pre-approved for Claude Code | `.claude/settings.json` |
| The `/milestone` workflow | `.claude/skills/milestone/SKILL.md` |
| Work handed from one session to the next (e.g. draft tests; create when needed) | `docs/handoff/` (see ROADMAP.md → Handoff) |

Update this table as milestones add files.

## Invariants

- `WorldClockCore` builds with Foundation alone.
- Compiler warnings are errors (package via `check.sh`, app via `SWIFT_TREAT_WARNINGS_AS_ERRORS` in `project.yml`).
- A `Zone` always holds a valid identifier (known IANA zones plus `UTC`), so `zone.timeZone` never fails. Abbreviations like `PST` are not identifiers.
- Time math is computed from offsets in seconds and a UTC Gregorian calendar, never `Calendar.current` or `TimeZone.current`. Minus signs in user-facing text are U+2212 (`−`), not hyphens.
- No package resources (the App Store export doesn't re-sign SwiftPM resource bundles). Images go in each app's asset catalog.

## Recipes

**Add a source file to the package:** create it under `Packages/WorldClockKit/Sources/<Module>/`. SwiftPM picks it up; no project regeneration needed.

**Snapshot a view:** add a `Snapshot` to `catalog` in `Tools/Snapshots/Sources/Snapshots/Catalog.swift`, built from fixed instants and zones (never the real clock). Run `swift run --package-path Tools/Snapshots Snapshots <name>`; output is `build/snapshots/<name>-light.png` and `-dark.png`. AppKit colors follow the drawing appearance the tool sets, so dark mode renders correctly.

**Add a file to the app target:** create it under `Apps/Mac/`, then run `xcodegen generate`.
