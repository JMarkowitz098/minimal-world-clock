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
| App entry point, windows (Clock ⌘1: hidden title bar, default size; Compare ⌘2; Settings ⌘,), the theme from the settings, wiring settings changes to the windows' locale and `WidgetCenter` reloads, app delegate (stay open when the last window closes) | `Apps/Mac/WorldClockMacApp.swift` |
| Palette credits shown in the standard About window | `Apps/Mac/Credits.rtf` |
| App sandbox and App Group entitlements | `Apps/Mac/WorldClock.entitlements` |
| Desktop widget: `Widget`, zone parameter (`SelectZoneIntent`, `ZoneEntity`, `ZoneEntityQuery`), timeline provider (reads the theme and 12/24-hour choice from the App Group into each entry), entry view. Thin: wraps the package types below | `Apps/Widget/MinimalWorldClockWidget.swift` |
| Widget sandbox and App Group entitlements | `Apps/Widget/MinimalWorldClockWidget.entitlements` |
| Targets, bundle IDs, versions, Info.plist keys, signing (development team for every build) and the widget's "Require team signing" build step | `project.yml` |
| Package targets | `Packages/WorldClockKit/Package.swift` |
| Time zone value (validation, city/region names, Codable, `Zone.utc`) | `WorldClockCore/Zone.swift` |
| What the user picked: a zone plus the city chosen in it (`Place`: "San Francisco" in America/Los_Angeles; `name`, `id` = `identifier#city` or the bare identifier, Codable as that string, so zones saved before M9 read as places) | `WorldClockCore/Place.swift` |
| Zone list and search: matching (city, cities in the zone, region, identifier, country, zone name, abbreviation), ranking (own city exact, other exact names, major prefix, other prefix, the rest), favorites first; `matches` returns places named for the matched city | `WorldClockCore/ZoneCatalog.swift` |
| The city table's parser (`CityTable`: aliases per zone, major cities, other country names) | `WorldClockCore/CityTable.swift` |
| The bundled city table: ~1,800 hand-written city names by zone (`*` = major, ranks first) and other country names ("UK", "Holland") | `WorldClockCore/CityData.swift` |
| Each zone's country and English zone names ("Japan", "Pacific Time"); generated, don't edit | `WorldClockCore/ZoneNames.swift` (by `scripts/make-zone-names.swift`) |
| Favorite places (`Favorites`: order, toggle) and their lenient saving (`SettingsStore.favorites`: unknown zones dropped and reported) | `WorldClockCore/Favorites.swift` |
| Wall-clock time at an instant, and wall time → instant (DST gaps and overlaps) | `WorldClockCore/WallTime.swift` |
| UTC offset text (`UTC+5:30`) and difference between zones (`−3 h 30 min`, `Same time`; spoken for VoiceOver: `3 hours 30 minutes behind`) | `WorldClockCore/Offsets.swift` |
| Reading a typed time of day (`9`, `9:30 pm`, `21:30`, `930`; no AM/PM keeps the edited time's half of the day in 12-hour locales) | `WorldClockCore/TimeEntry.swift` |
| Yesterday / today / tomorrow relative to another zone | `WorldClockCore/DayRelation.swift` |
| When a zone's date, AM/PM or offset next changes (next midnight, noon or DST transition): the widget's timeline dates | `WorldClockCore/DisplayChanges.swift` |
| The widget's zone lookups (resolve place IDs, search, suggestions with favorites first, default) and `Zone(systemZone:)` (the Mac's zone or UTC) | `WorldClockCore/ZoneQuery.swift` |
| The Settings window's saved choices (`AppSettings`: `TimeFormat` system/12/24-hour, theme ID), decoded leniently per key with unreadable values reported; `SettingsStore.appSettings` | `WorldClockCore/AppSettings.swift` |
| Saved settings: the `SettingsStore` protocol, its keys, typed accessors (`clockPlace`, `comparePlaceA`, `comparePlaceB`, stored under the pre-M9 keys `clockZone`, `compareZoneA`, `compareZoneB`; `favorites` is in `Favorites.swift`, `appSettings` is in `AppSettings.swift`), UserDefaults and in-memory stores; `reportUnreadable` for values that can't be read (the app logs them) | `WorldClockCore/SettingsStore.swift` |
| Fixed test instants and helpers (`jan15Noon`, `mar15Noon`, `utc(…)`, `wall(…)`, `zone(…)`) | `Tests/WorldClockCoreTests/TestSupport.swift` |
| Ticking on minute boundaries: the `Ticker` protocol, the app's `DispatchTicker`, `Date.nextMinuteBoundary` | `WorldClockUI/Ticker.swift` |
| The view models' current time: read now and on each minute boundary between `start` and `stop` (`MinuteClock`; the one place ticking rules change, e.g. pausing while minimized in M10) | `WorldClockUI/MinuteClock.swift` |
| Logging for Console.app (`Log.settings`, `Log.widget`) and the app's logging settings store (`UserDefaultsSettingsStore.live()`) | `WorldClockUI/Log.swift` |
| A zone's display strings (time, date, city; `time` also as an `AttributedString` marking AM/PM) and the formatters that build them (`ZoneDisplay`, `ZoneFormatter`, and the widget's hours-and-minutes format), shared by both windows and the widget | `WorldClockUI/ZoneDisplay.swift` |
| The 12/24-hour setting as a locale (`Locale.applying(_: TimeFormat)` sets the hour cycle, `en_US@hours=h23`, so every formatter follows) and whether a locale shows 12-hour time (`Locale.usesTwelveHourTime`; Compare's typed times, the widget's AM/PM) | `WorldClockUI/Locale+TimeFormat.swift` |
| The App Group shared with the widget (`AppGroup.id`, team-ID prefixed) and its settings store | `WorldClockUI/AppGroup.swift` |
| Settings window model: 12/24-hour, theme, launch at login (`LoginItem`, `MainAppLoginItem` over `SMAppService.mainApp`), the resulting `locale`, `onChange` (`.locale` / `.theme`), the Mac's region changes; `live()` | `WorldClockUI/SettingsViewModel.swift` |
| Settings window (standard form: Time, Open at login, theme swatch grid) | `WorldClockUI/SettingsView.swift` |
| Every text size (windows', widget's) and the time with a smaller AM/PM (`TimeStyle.shrinkingDayPeriod`, windows only) | `WorldClockUI/TimeStyle.swift` |
| Color themes (background, text, accent, a softer `surface` for popovers, `isDark`; some colors nudged for WCAG AA, marked "AA"), the list Settings offers (`Theme.all`, `Theme.named`, `Theme.default`); Increase Contrast (`increasedContrast`, `line(_:)` for faint lines and fills, `ring(_:)` for accent rings, `Theme.hoverFill`); the `\.theme` environment value and `.themed(_:)` (sets it with the Mac's Increase Contrast setting, and the window's light/dark appearance), which each window and the widget apply once | `WorldClockUI/Theme.swift` |
| Keeps a window at its content's proportions while resizing (`NSWindow.contentAspectRatio`, macOS only) | `WorldClockUI/WindowAspectRatio.swift` |
| Names a window's hosting view for VoiceOver ("Clock", "Compare"; unnamed, Accessibility Inspector's audit flags it) | `WorldClockUI/WindowAccessibilityName.swift` |
| Clock window display strings (and `spokenText` for VoiceOver), ticking, place choice (zone + picked city) and its persistence, `setLocale` (12/24-hour changes); `ClockViewModel.live(locale:)` wires the app's dependencies | `WorldClockUI/ClockViewModel.swift` |
| The frame both windows share (`ScalingWindow`): no title bar, theme background and text color, content scaling with the window (`WindowLayout.scale(fitting:in:)`), aspect ratio, hover edge, click to end typing, drag to move, top strip, the window's VoiceOver name | `WorldClockUI/ScalingWindow.swift` |
| Hover effects: `.trackingHover($isHovered)` (fades with `Animation.hover`, instant with Reduce Motion) | `WorldClockUI/Hover.swift` |
| Clock window content: time and date (time in the accent while hovered), city + globe in the top strip; start/stop on appear/disappear | `WorldClockUI/ClockView.swift` |
| Compare window: two zones at one instant, live vs. scrubbed, swap, Now, typed times (`typeTimeA`/`typeTimeB`), difference and day-relation text, B's date with its day (`zoneBDateText`), scrubber hour labels, the widest B date for sizing (`widestZoneBDateText`), VoiceOver text (`spokenDifference`, `zoneBSpokenDate`, `scrubberSpokenValue`), persistence, `setLocale`; `live(locale:)` | `WorldClockUI/CompareViewModel.swift` |
| Compare window layout (design H): city + globe, click-to-type time and date per zone; accent difference and swap between (hover circle); 24-hour strip; "Now" pill in the title bar strip while scrubbed; frame from `ScalingWindow`; scales with the window like the Clock (natural size measured with `TimeStyle.widestTime` so it doesn't change while scrubbing) | `WorldClockUI/CompareView.swift` |
| Large time that turns into a text field when clicked (hover: accent background + text cursor; Return commits, Esc cancels, unreadable input beeps; clicking elsewhere commits a time or reverts); keyboard: Tab reaches it (solid accent ring), Return or Space opens it, focus returns after Return or Esc | `WorldClockUI/EditableTime.swift` |
| 24-hour scrubber drawn in theme colors (the system slider ignores tint): hourly ticks, labels, accent fill and thumb; hover darkens and thickens the track, rings the thumb, and marks the quarter hour a click would jump to; quarter-hour snapping; arrow keys adjust; a solid accent ring shows keyboard focus; VoiceOver sees a standard slider (`accessibilityRepresentation`) whose value names both zones' times | `WorldClockUI/TimeStrip.swift` |
| Thin accent edge along the window while hovered (Clock and Compare) | `WorldClockUI/HoverEdge.swift` |
| The widget's strings at an entry date (city, date, short date) and its live hours-and-minutes format with the fixed `timeText` that sizes it, AM/PM as fixed text (nil in 24-hour locales), and the timeline's dates (`entryDates`: date, AM/PM or the time's width changes, and DST transitions) | `WorldClockUI/WidgetDisplay.swift` |
| The widget's container background: theme background and a thin border in the text color, 6 pt in from the edge, corners concentric with the widget's | `WorldClockUI/WidgetBackground.swift` |
| The widget's layout: medium in the Clock window's look (city top-right in the accent, time with a smaller AM/PM and date centered); small with city and date top-left, time bottom-left; theme colors (no WidgetKit import; snapshots can freeze the time) | `WorldClockUI/ZoneWidgetView.swift` |
| Button that opens the zone picker in a popover: the place's city with globe and hover pill (Clock and Compare); passes `\.theme` and the environment's `FavoritesModel` on to the picker (a popover is a separate window) |
| The favorites both windows' pickers share (`FavoritesModel`, `live()` saves in the App Group for the widget); the app puts one in the environment | `WorldClockUI/FavoritesModel.swift` | `WorldClockUI/ZoneButton.swift` |
| Zone search rows (`place`, `city`, `Asia · UTC+9` or the zone's city for a matched city, `isFavorite`, `spokenLabel` without the `·`), favorites first (`favoriteCount`, fixed until the next search so a starred row doesn't move), `toggleFavorite`, the keyboard highlight (`moveHighlight(by:)`, `choice` for Return) | `WorldClockUI/ZonePickerViewModel.swift` |
| Zone search field and results list, drawn in the window's theme (surface background, accent ring, cursor, hover, checkmark, stars); favorites in a first section with a stronger line under it; a star on hover (filled for favorites), right-click and a VoiceOver action toggle a favorite; ↓/↑ in the field highlight a row (solid accent outline), Return picks it, ⌘D stars it | `WorldClockUI/ZonePicker.swift` |
| WCAG AA contrast of every theme (text, accent, hovered states, the Now pill) and the Increase Contrast helpers | `Tests/WorldClockUITests/ThemeContrastTests.swift` |
| What VoiceOver reads (Clock, Compare, picker rows) | `Tests/WorldClockUITests/SpokenTextTests.swift` |
| Wider search (countries, zone names, city table, ranking), favorites, places | `Tests/WorldClockCoreTests/ZoneSearchTests.swift`, `FavoritesTests.swift`, `PlaceTests.swift` |
| UI test helpers (`FakeClock`, `FakeTicker`, `makeClock(…)`, `makeCompare(…)`, `nnbsp`) | `Tests/WorldClockUITests/TestSupport.swift` |
| Views rendered for visual checks (and later App Store screenshots) | `Tools/Snapshots/Sources/Snapshots/Catalog.swift` |
| Temporary design option sheets (`prototypes`, rendered to `build/prototypes/`; empty between explorations) | `Tools/Snapshots/Sources/Snapshots/Prototypes.swift` |
| The snapshot renderer (offscreen `NSHostingView`, light and dark, 2×, plus Increase Contrast variants; catalog → `build/snapshots/`, prototypes → `build/prototypes/`; deletes renders no entry makes) | `Tools/Snapshots/Sources/Snapshots/Snapshots.swift` |
| Regenerating `ZoneNames.swift` from macOS's `zone.tab` and Foundation's English names | `scripts/make-zone-names.swift` |
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
- View models take their clock (`() -> Date`), `Ticker`, `SettingsStore`, and `Locale` as init parameters; only the `live()` factories and the widget's timeline provider (the entry points) touch `Date()`, `TimeZone.current`, `UserDefaults`, or the App Group.
- The 12/24-hour setting is applied to the locale (`Locale.applying`), never as a separate flag: the windows get the settings' `locale` (`setLocale` on a change) and the widget applies it to `Locale.current`. SwiftUI's `Text(_:format:)` takes the environment's locale too, so the widget view sets `\.locale`.
- The Settings choices live in the App Group's defaults (the widget reads them); the windows' zones stay in the app's own defaults. After a change the app calls `WidgetCenter.shared.reloadAllTimelines()`; macOS redraws the widget seconds later (no faster API).
- A view model schedules one tick at a time, at the next minute boundary, and only between `start()` and `stop()`, which views call from `onAppear` / `onDisappear`. Nothing repeats on its own.
- Display strings for a zone come from `ZoneFormatter`, so the Clock and Compare windows format time and date identically. Keep one formatter per shown zone (creating a `DateFormatter` is costly) and update its `zone` rather than rebuilding it.
- The widget's hours and minutes are live text (`Text(.currentDate, format:)`, macOS 15+); its timeline has entries only when the date, AM/PM or offset changes (`Zone.displayChanges`: midnight, noon, DST), plus when the time's width changes (`WidgetDisplay.entryDates`: 9:59 → 10:00, 12:59 → 1:00), so the extension runs a few times a day. Never add per-minute entries.
- Views read colors from `@Environment(\.theme)`; only entry points (the app's scenes, the widget's entry view and container background, snapshots) choose the theme, with `.themed(_:)`. Popovers get it passed on explicitly. Never pass a `Theme` as a parameter (the Settings swatches, which draw every theme, are the exception). The Settings window itself uses the system look.
- Hover effects use `.trackingHover` (or `Animation.hover` with a Reduce Motion check where `onContinuousHover` is needed), so Reduce Motion turns every fade off. Text sizes come from `TimeStyle`, not literals.
- **Contrast (M8, WCAG AA):** text is drawn solid in `theme.text` or `theme.accent`, never faded with opacity (faded secondary text failed on the softer themes). Faint lines, ticks and quiet fills use `theme.line(_:)` and accent rings and edges `theme.ring(_:)`, which Increase Contrast strengthens; a fill behind text uses `Theme.hoverFill` (6%). A keyboard focus indicator (focused time, the strip's thumb, the picker's highlighted row) is solid `theme.accent`, not a soft ring, so it reaches 3:1. `ThemeContrastTests` checks every theme's colors (and blends the way macOS draws: gamma-encoded sRGB, not linear light).
- **VoiceOver:** what a view reads comes from its view model (`spokenText`, `spokenDifference`, `scrubberSpokenValue`, `Row.spokenLabel`), tested in `SpokenTextTests`, so `·`, `+14 h` and `−` are never read literally. Compare groups each zone (`.accessibilityElement(children: .contain)` with a label); an element that ignores its children gets `.isStaticText` (else it's AXUnknown); a custom control that adjusts uses `accessibilityRepresentation` with a standard `Slider` (an adjustable action alone came through as AXUnknown with no value).
- **Key handlers on a view that contains a text field** see every key typed into the field; return `.ignored` unless the view itself should act (EditableTime's Return/Space swallowed the field's Return and spaces until they did).
- What fails or falls back silently is logged (`Log`, UI and widget only; Core reports through hooks like `SettingsStore.reportUnreadable`, since it can't import `os`). Never log per tick.
- SwiftUI's `Text(_:format:)` formats dates in the environment's `\.timeZone`, ignoring the format style's own zone, so a view showing another zone's time with it must set `.environment(\.timeZone, …)`. (The windows format strings with `ZoneFormatter` instead.) Snapshots won't catch a miss when the zone shown matches the Mac's.
- Names the system sees (targets, products, widget kind, gallery name) start with "Minimal World Clock" / `MinimalWorldClock…`: Apple's Clock app already ships a "World Clock" widget whose extension is `WorldClockWidget`. Bundle IDs: `com.jaredmarkowitz.minimalworldclock` and `….widget` (permanent once on the App Store).
- Every build is signed with the development team. Ad-hoc signed, the widget shows up but macOS silently drops the zone picked in its edit screen. The widget target's "Require team signing" build step and `check.sh`'s signature check enforce this.
- The widget's live time uses a system format only (`Date.FormatStyle`): macOS draws widgets from an archived view, and with a custom `DiscreteFormatStyle` the widget stays on its placeholder. On the desktop a live `Text` also takes all the width it can (it pushed the time off center), so the live hours and minutes are laid over a hidden fixed copy (`timeText`) that sets their size, and AM/PM is a separate fixed `Text` drawn smaller; the timeline refreshes them when they change.
- Windows without a title bar (Clock): content respects the top safe area (the title bar strip); only the background and the strip's controls extend into it. Snapshots of such a view add `.safeAreaPadding(.top, 28)`.
- A view's `.foregroundStyle` also colors the popovers it presents, so a button that opens a popover colors its own label (`ZoneButton` does) instead of the caller styling the button.
- App Intents types (`AppEntity`, `WidgetConfigurationIntent`) live in the widget target, where Xcode extracts their metadata; their logic lives in the package (`ZoneQuery`).
- **Places, not zones, for what the user picked** (M9): the windows, favorites and the widget's entity hold a `Place` (zone + picked city) and show `place.name`; time math uses `place.zone`. Saved as `Place.id`, which is a bare identifier for the zone's own city, so data saved as a `Zone` still reads.
- Search names are English (`ZoneNames` is generated in English; asking Foundation at launch cost ~30 ms per process). Localized names belong with the "Later" localization work.
- Settings are read leniently: missing, corrupt, or unknown data reads as `nil` and the caller uses its default. `SettingsKey` values are never renamed.

## Recipes

**Add a source file to the package:** create it under `Packages/WorldClockKit/Sources/<Module>/`. SwiftPM picks it up; no project regeneration needed.

**Add a saved setting:** a Settings window choice goes in `AppSettings` (a property with a default, a `CodingKeys` case, and a `value(…) ?? default` line in its lenient `init(from:)`), then a property on `SettingsViewModel` that saves and calls `onChange`, and a control in `SettingsView`; the widget sees it through the App Group. Per-window state (like a zone) gets its own key in `SettingsKey` and a typed property beside `clockZone` in `SettingsStore.swift` (Codable, `nil` when unreadable). Test missing, corrupt and unknown values with `InMemorySettingsStore`.

**Add a city to search:** add its name to its zone's line in `CityData.swift` (`*` before it if it's a major metro; a city that names a zone needs no entry). Same-named cities in different zones are fine (the row's detail shows the zone's city); `everyCityPointsToAKnownZone` rejects unknown zones, a zone's own city and duplicates within a zone. For a country nickname, add it to `CityData.countryNames` by ISO code.

**Add a theme:** add a `static let` in `Theme.swift` with a new, permanent `id` (it's saved), set `isDark` to match the background (`darkThemesHaveDarkBackgrounds` checks), make it pass `ThemeContrastTests` (darken or lighten the accent in the same hue if needed, and say so in the credits), add it to `Theme.all`, credit its palette in `Apps/Mac/Credits.rtf` and design_doc.md, and look at the `themes` and `settings` snapshots.

**Snapshot a view:** add a `Snapshot` to `catalog` in `Tools/Snapshots/Sources/Snapshots/Catalog.swift`, built from fixed instants and zones (never the real clock). Run `swift run --package-path Tools/Snapshots Snapshots <name>`; output is `build/snapshots/<name>-light.png` and `-dark.png` (only `-light` for `lightOnly` entries, whose colors don't depend on the appearance, like `themes`), with `increasedContrast: true` also `-light-contrast.png`/`-dark-contrast.png` drawn with Increase Contrast (set through `\._colorSchemeContrast`, as Xcode previews do: the high-contrast `NSAppearance` alone doesn't reach SwiftUI offscreen), and every run deletes PNGs no catalog entry makes (so a removed prototype's renders go with it). The tool draws through an offscreen `NSHostingView` (not `ImageRenderer`, which can't draw text fields, lists or sliders) with the light or dark appearance set, so AppKit controls and colors render correctly. For a view model, pass fixed instants, `InMemorySettingsStore`, `Locale(identifier: "en_US")`, and the catalog's `StillTicker` (the `clockModel`/`compareModel`/`settingsModel` helpers do this; `compareModel(…, scrubTo:)` renders a scrubbed state). `.renderTheme()` draws Solarized light in the light render and Solarized dark in the dark one; a view that sets the window's aspect ratio (`ClockView`, `CompareView`) resizes the tool's offscreen window, so on a multi-view sheet draw a static mock instead. Keep each sheet shorter than the screen (a taller offscreen window gets clamped and shifts the render).

**Explore a design with the user:** add a prototype file under `Tools/Snapshots/Sources/Snapshots/` (e.g. `WidgetOptions.swift`), register its sheet in `prototypes` (`Prototypes.swift`, not the catalog; renders go to `build/prototypes/`, apart from the real snapshots), and put 4–8 options on one sheet, two per row, each in a mock window frame with fixed dates and zones; render and let the user pick or mix (keep the ones they keep, drop the rest, and iterate). Build only the chosen option into WorldClockUI, then delete the prototype file and its `prototypes` entry (the next run removes its renders). Examples in git history: `ClockOptions.swift`, `CompareOptions.swift` (at commit 8ab9350, with `TrafficLights` for mock window buttons) and `WidgetOptions.swift` (three widget rounds; the last at commit 4629500).

**Add a window:** build its content on `ScalingWindow` (theme, scaling, hover edge, drag) and apply `.themed(settings.theme)` where the scene creates it; add a `Window` scene in `Apps/Mac/WorldClockMacApp.swift` with `.keyboardShortcut` (it gets a Window menu item automatically) and `.defaultSize` if the content has a greedy control (a `Slider`'s ideal width is 900 pt; `frame(idealWidth:)` doesn't help). The first scene opens at launch. macOS autosaves each window's frame (`NSWindow Frame <id>` in the app's defaults), so after changing a default size, delete that key before checking it.

**Add a file to the app or widget target:** create it under `Apps/Mac/` or `Apps/Widget/`, then run `xcodegen generate`.

**Change the widget:** content and strings go in `WidgetDisplay` / `ZoneWidgetView` (tested and snapshotted: `widget-*` entries, which pass `frozenTime`); WidgetKit glue in `Apps/Widget/MinimalWorldClockWidget.swift`. Bump the widget's `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml` with the app's. To try it, install to /Applications (CLAUDE.md → Commands).
