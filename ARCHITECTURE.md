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
| App entry point, windows, app delegate (stay open when the last window closes) | `Apps/Mac/WorldClockMacApp.swift` |
| App sandbox entitlements | `Apps/Mac/WorldClock.entitlements` |
| Targets, bundle IDs, versions, Info.plist keys | `project.yml` |
| Package targets | `Packages/WorldClockKit/Package.swift` |
| Time zone value (validation, city/region names, Codable) | `WorldClockCore/Zone.swift` |
| Zone list and search (matching, ranking) | `WorldClockCore/ZoneCatalog.swift` |
| Wall-clock time at an instant, and wall time → instant (DST gaps and overlaps) | `WorldClockCore/WallTime.swift` |
| UTC offset text (`UTC+5:30`) and difference between zones (`−3 h 30 min`, `Same time`) | `WorldClockCore/Offsets.swift` |
| Yesterday / today / tomorrow relative to another zone | `WorldClockCore/DayRelation.swift` |
| Saved settings: the `SettingsStore` protocol, its keys, typed accessors (`clockZone`), UserDefaults and in-memory stores | `WorldClockCore/SettingsStore.swift` |
| Fixed test instants and helpers (`jan15Noon`, `mar15Noon`, `utc(…)`, `wall(…)`, `zone(…)`) | `Tests/WorldClockCoreTests/TestSupport.swift` |
| Ticking on minute boundaries: the `Ticker` protocol and the app's `DispatchTicker` | `WorldClockUI/Ticker.swift` |
| Clock window display strings, ticking, zone choice and its persistence; `ClockViewModel.live()` wires the app's dependencies | `WorldClockUI/ClockViewModel.swift` |
| Clock window layout (zone button, popover picker, start/stop on appear/disappear) | `WorldClockUI/ClockView.swift` |
| Large time + date + offset under a title (shared with Compare) | `WorldClockUI/TimeDisplay.swift` |
| Zone search rows (`city`, `Asia · UTC+9`) | `WorldClockUI/ZonePickerViewModel.swift` |
| Zone search field and results list | `WorldClockUI/ZonePicker.swift` |
| UI test helpers (`FakeClock`, `FakeTicker`, `makeClock(…)`, `nnbsp`) | `Tests/WorldClockUITests/TestSupport.swift` |
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
- View models take their clock (`() -> Date`), `Ticker`, `SettingsStore`, and `Locale` as init parameters; only the `live()` factories touch `Date()`, `TimeZone.current`, or `UserDefaults.standard`.
- A view model schedules one tick at a time, at the next minute boundary, and only between `start()` and `stop()`, which views call from `onAppear` / `onDisappear`. Nothing repeats on its own.
- Settings are read leniently: missing, corrupt, or unknown data reads as `nil` and the caller uses its default. `SettingsKey` values are never renamed.

## Recipes

**Add a source file to the package:** create it under `Packages/WorldClockKit/Sources/<Module>/`. SwiftPM picks it up; no project regeneration needed.

**Add a saved setting:** add a key to `SettingsKey` and a typed property beside `clockZone` in `SettingsStore.swift` (Codable value, `nil` when unreadable). Test missing and corrupt data with `InMemorySettingsStore`.

**Snapshot a view:** add a `Snapshot` to `catalog` in `Tools/Snapshots/Sources/Snapshots/Catalog.swift`, built from fixed instants and zones (never the real clock). Run `swift run --package-path Tools/Snapshots Snapshots <name>`; output is `build/snapshots/<name>-light.png` and `-dark.png`. The tool draws through an offscreen `NSHostingView` (not `ImageRenderer`, which can't draw text fields, lists or sliders) with the light or dark appearance set, so AppKit controls and colors render correctly. For a view model, pass fixed instants, `InMemorySettingsStore`, `Locale(identifier: "en_US")`, and the catalog's `StillTicker`.

**Add a file to the app target:** create it under `Apps/Mac/`, then run `xcodegen generate`.
