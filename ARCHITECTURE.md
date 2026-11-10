# Architecture

How the code fits together and where things live. Rules are in [CLAUDE.md](CLAUDE.md); milestones are in [ROADMAP.md](ROADMAP.md).

## Layers

```
Apps/Mac (thin shell)    ──uses──▶  WorldClockUI  ──uses──▶  WorldClockCore
Apps/Widget (WidgetKit)             view models,             zones, search, time math,
                                    shared views             settings (Foundation only)
```

Dependencies only point right. An iOS app would sit beside `Apps/Mac` and use the same modules.

## File map

| Need to change… | File |
|---|---|
| App entry point, windows (Clock ⌘1: hidden title bar, default size, theme; Compare ⌘2), app delegate (stay open when the last window closes) | `Apps/Mac/WorldClockMacApp.swift` |
| App sandbox entitlements | `Apps/Mac/WorldClock.entitlements` |
| Desktop widget: `Widget`, zone parameter (`SelectZoneIntent`, `ZoneEntity`, `ZoneEntityQuery`), timeline provider, entry view. Thin: wraps the package types below | `Apps/Widget/MinimalWorldClockWidget.swift` |
| Widget sandbox entitlements | `Apps/Widget/MinimalWorldClockWidget.entitlements` |
| Targets, bundle IDs, versions, Info.plist keys, signing (development team for every build) and the widget's "Require team signing" build step | `project.yml` |
| Package targets | `Packages/WorldClockKit/Package.swift` |
| Time zone value (validation, city/region names, Codable, `Zone.utc`) | `WorldClockCore/Zone.swift` |
| Zone list and search (matching, ranking) | `WorldClockCore/ZoneCatalog.swift` |
| Wall-clock time at an instant, and wall time → instant (DST gaps and overlaps) | `WorldClockCore/WallTime.swift` |
| UTC offset text (`UTC+5:30`) and difference between zones (`−3 h 30 min`, `Same time`) | `WorldClockCore/Offsets.swift` |
| Reading a typed time of day (`9`, `9:30 pm`, `21:30`, `930`; no AM/PM keeps the edited time's half of the day in 12-hour locales) | `WorldClockCore/TimeEntry.swift` |
| Yesterday / today / tomorrow relative to another zone | `WorldClockCore/DayRelation.swift` |
| When a zone's date, AM/PM or offset next changes (next midnight, noon or DST transition): the widget's timeline dates | `WorldClockCore/DisplayChanges.swift` |
| The widget's zone lookups (resolve identifiers, search, suggestions, default) and `Zone(systemZone:)` (the Mac's zone or UTC) | `WorldClockCore/ZoneQuery.swift` |
| Saved settings: the `SettingsStore` protocol, its keys, typed accessors (`clockZone`, `compareZoneA`, `compareZoneB`), UserDefaults and in-memory stores | `WorldClockCore/SettingsStore.swift` |
| Fixed test instants and helpers (`jan15Noon`, `mar15Noon`, `utc(…)`, `wall(…)`, `zone(…)`) | `Tests/WorldClockCoreTests/TestSupport.swift` |
| Ticking on minute boundaries: the `Ticker` protocol, the app's `DispatchTicker`, `Date.nextMinuteBoundary` | `WorldClockUI/Ticker.swift` |
| A zone's display strings (time, date, city; `time` also as an `AttributedString` marking AM/PM) and the formatters that build them (`ZoneDisplay`, `ZoneFormatter`, and the widget's hours-and-minutes format), shared by both windows and the widget | `WorldClockUI/ZoneDisplay.swift` |
| Whether a locale shows 12-hour time (`Locale.usesTwelveHourTime`; Compare's typed times, the widget's AM/PM) | `WorldClockUI/Locale+TwelveHour.swift` |
| Shared type sizes and the time with a smaller AM/PM (`TimeStyle.shrinkingDayPeriod`, windows only) | `WorldClockUI/TimeStyle.swift` |
| Color themes (background, text, accent, and a softer `surface` for popovers) and light/dark pairs (`ThemePair.solarized`: the window follows the Mac's appearance); a Settings choice in M7 | `WorldClockUI/Theme.swift` |
| Keeps a window at its content's proportions while resizing (`NSWindow.contentAspectRatio`, macOS only) | `WorldClockUI/WindowAspectRatio.swift` |
| Clock window display strings, ticking, zone choice and its persistence; `ClockViewModel.live()` wires the app's dependencies | `WorldClockUI/ClockViewModel.swift` |
| Clock window layout: city + globe in the title bar strip, time and date scaling with the window, theme colors, hover highlight, drag anywhere to move (start/stop on appear/disappear) | `WorldClockUI/ClockView.swift` |
| Compare window: two zones at one instant, live vs. scrubbed, swap, Now, typed times (`typeTimeA`/`typeTimeB`), difference and day-relation text, B's date with its day (`zoneBDateText`), scrubber hour labels, the widest B date for sizing (`widestZoneBDateText`), persistence; `live()` | `WorldClockUI/CompareViewModel.swift` |
| Compare window layout (design H): city + globe, click-to-type time and date per zone; accent difference and swap between (hover circle); 24-hour strip; "Now" pill in the title bar strip while scrubbed; theme colors, hover edge, drag background to move; scales with the window like the Clock (natural size measured with `TimeStyle.widestTime` so it doesn't change while scrubbing) | `WorldClockUI/CompareView.swift` |
| Large time that turns into a text field when clicked (hover: accent background + text cursor; Return commits, Esc cancels, unreadable input beeps; clicking elsewhere commits a time or reverts) | `WorldClockUI/EditableTime.swift` |
| 24-hour scrubber drawn in theme colors (the system slider ignores tint): hourly ticks, labels, accent fill and thumb; hover darkens and thickens the track, rings the thumb, and marks the quarter hour a click would jump to; quarter-hour snapping; arrow keys and VoiceOver adjust | `WorldClockUI/TimeStrip.swift` |
| Thin accent edge along the window while hovered (Clock and Compare) | `WorldClockUI/HoverEdge.swift` |
| The widget's strings at an entry date (city, date, short date) and its live hours-and-minutes format with the fixed `timeText` that sizes it, AM/PM as fixed text (nil in 24-hour locales), and the timeline's dates (`entryDates`: date, AM/PM or the time's width changes, and DST transitions) | `WorldClockUI/WidgetDisplay.swift` |
| The widget's container background: theme background and a thin border in the text color, 6 pt in from the edge, corners concentric with the widget's | `WorldClockUI/WidgetBackground.swift` |
| The widget's layout: medium in the Clock window's look (city top-right in the accent, time with a smaller AM/PM and date centered); small with city and date top-left, time bottom-left; theme colors (no WidgetKit import; snapshots can freeze the time) | `WorldClockUI/ZoneWidgetView.swift` |
| Button that opens the zone picker in a popover: city with globe and hover pill (Clock and Compare); passes its theme to the popover | `WorldClockUI/ZoneButton.swift` |
| Zone search rows (`city`, `Asia · UTC+9`) | `WorldClockUI/ZonePickerViewModel.swift` |
| Zone search field and results list, drawn in the window's theme (surface background, accent ring, cursor, hover and checkmark) | `WorldClockUI/ZonePicker.swift` |
| UI test helpers (`FakeClock`, `FakeTicker`, `makeClock(…)`, `makeCompare(…)`, `nnbsp`) | `Tests/WorldClockUITests/TestSupport.swift` |
| Views rendered for visual checks (and later App Store screenshots) | `Tools/Snapshots/Sources/Snapshots/Catalog.swift` |
| The snapshot renderer (offscreen `NSHostingView`, light and dark, 2×; deletes renders no catalog entry makes) | `Tools/Snapshots/Sources/Snapshots/Snapshots.swift` |
| What the pre-commit check runs (tests, app build, team-signing check, snapshot tool build) | `scripts/check.sh` (hook: `scripts/hooks/pre-commit`) |
| One-time setup after cloning (installs the hook, generates the Xcode project) | `scripts/setup.sh` |
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
- View models take their clock (`() -> Date`), `Ticker`, `SettingsStore`, and `Locale` as init parameters; only the `live()` factories and the widget's timeline provider (the entry points) touch `Date()`, `TimeZone.current`, or `UserDefaults.standard`.
- A view model schedules one tick at a time, at the next minute boundary, and only between `start()` and `stop()`, which views call from `onAppear` / `onDisappear`. Nothing repeats on its own.
- Display strings for a zone come from `ZoneFormatter`, so the Clock and Compare windows format time and date identically. Keep one formatter per shown zone (creating a `DateFormatter` is costly) and update its `zone` rather than rebuilding it.
- The widget's hours and minutes are live text (`Text(.currentDate, format:)`, macOS 15+); its timeline has entries only when the date, AM/PM or offset changes (`Zone.displayChanges`: midnight, noon, DST), plus when the time's width changes (`WidgetDisplay.entryDates`: 9:59 → 10:00, 12:59 → 1:00), so the extension runs a few times a day. Never add per-minute entries.
- SwiftUI's `Text(_:format:)` formats dates in the environment's `\.timeZone`, ignoring the format style's own zone, so a view showing another zone's time with it must set `.environment(\.timeZone, …)`. (The windows format strings with `ZoneFormatter` instead.) Snapshots won't catch a miss when the zone shown matches the Mac's.
- Names the system sees (targets, products, widget kind, gallery name) start with "Minimal World Clock" / `MinimalWorldClock…`: Apple's Clock app already ships a "World Clock" widget whose extension is `WorldClockWidget`. Bundle IDs: `com.jaredmarkowitz.minimalworldclock` and `….widget` (permanent once on the App Store).
- Every build is signed with the development team. Ad-hoc signed, the widget shows up but macOS silently drops the zone picked in its edit screen. The widget target's "Require team signing" build step and `check.sh`'s signature check enforce this.
- The widget's live time uses a system format only (`Date.FormatStyle`): macOS draws widgets from an archived view, and with a custom `DiscreteFormatStyle` the widget stays on its placeholder. On the desktop a live `Text` also takes all the width it can (it pushed the time off center), so the live hours and minutes are laid over a hidden fixed copy (`timeText`) that sets their size, and AM/PM is a separate fixed `Text` drawn smaller; the timeline refreshes them when they change.
- Windows without a title bar (Clock): content respects the top safe area (the title bar strip); only the background and the strip's controls extend into it. Snapshots of such a view add `.safeAreaPadding(.top, 28)`.
- A view's `.foregroundStyle` also colors the popovers it presents, so a button that opens a popover colors its own label (`ZoneButton` does) instead of the caller styling the button.
- App Intents types (`AppEntity`, `WidgetConfigurationIntent`) live in the widget target, where Xcode extracts their metadata; their logic lives in the package (`ZoneQuery`).
- Settings are read leniently: missing, corrupt, or unknown data reads as `nil` and the caller uses its default. `SettingsKey` values are never renamed.

## Recipes

**Add a source file to the package:** create it under `Packages/WorldClockKit/Sources/<Module>/`. SwiftPM picks it up; no project regeneration needed.

**Add a saved setting:** add a key to `SettingsKey` and a typed property beside `clockZone` in `SettingsStore.swift` (Codable value, `nil` when unreadable). Test missing and corrupt data with `InMemorySettingsStore`.

**Snapshot a view:** add a `Snapshot` to `catalog` in `Tools/Snapshots/Sources/Snapshots/Catalog.swift`, built from fixed instants and zones (never the real clock). Run `swift run --package-path Tools/Snapshots Snapshots <name>`; output is `build/snapshots/<name>-light.png` and `-dark.png`, and every run deletes PNGs no catalog entry makes (so a removed prototype's renders go with it). The tool draws through an offscreen `NSHostingView` (not `ImageRenderer`, which can't draw text fields, lists or sliders) with the light or dark appearance set, so AppKit controls and colors render correctly. For a view model, pass fixed instants, `InMemorySettingsStore`, `Locale(identifier: "en_US")`, and the catalog's `StillTicker` (the `clockModel`/`compareModel` helpers do this; `compareModel(…, scrubTo:)` renders a scrubbed state).

**Explore a design with the user:** add a prototype file under `Tools/Snapshots/Sources/Snapshots/` (e.g. `WidgetOptions.swift`), register its sheet in `Catalog.swift`, and put 4–8 options on one sheet, two per row, each in a mock window frame with fixed dates and zones; render and let the user pick or mix (keep the ones they keep, drop the rest, and iterate). Build only the chosen option into WorldClockUI, then delete the prototype file. Examples in git history: `ClockOptions.swift`, `CompareOptions.swift` (at commit 8ab9350, with `TrafficLights` for mock window buttons) and `WidgetOptions.swift` (three widget rounds; the last at commit 4629500).

**Add a window:** add a `Window` scene in `Apps/Mac/WorldClockMacApp.swift` with `.keyboardShortcut` (it gets a Window menu item automatically) and `.defaultSize` if the content has a greedy control (a `Slider`'s ideal width is 900 pt; `frame(idealWidth:)` doesn't help). The first scene opens at launch. macOS autosaves each window's frame (`NSWindow Frame <id>` in the app's defaults), so after changing a default size, delete that key before checking it.

**Add a file to the app or widget target:** create it under `Apps/Mac/` or `Apps/Widget/`, then run `xcodegen generate`.

**Change the widget:** content and strings go in `WidgetDisplay` / `ZoneWidgetView` (tested and snapshotted: `widget-*` entries, which pass `frozenTime`); WidgetKit glue in `Apps/Widget/MinimalWorldClockWidget.swift`. Bump the widget's `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml` with the app's. To try it, install to /Applications (CLAUDE.md → Commands).
