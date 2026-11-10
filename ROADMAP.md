# Roadmap

Each milestone fits in one session. Its "Tests" are the acceptance criteria: write them first (TDD). "Done when" is the check before committing (see CLAUDE.md → Git). **Stop after each milestone and check in before starting the next.**

Shared commands: `./scripts/check.sh` (all tests + app build). Use `swift test --package-path Packages/WorldClockKit` for fast TDD loops.

## Handoff (read first; rewrite at the end of every session)

Each milestone runs in a new chat, so this section carries what the next session needs and the code and git history can't show.

- **Last session (2026-11-10):** M1 done: `Zone` and `ZoneCatalog` in `WorldClockCore` (19 core tests green). The draft tests from `docs/handoff/` were moved into `Tests/WorldClockCoreTests/` and the drafts folder deleted. Earlier: M0 plus AI tooling (`/milestone` skill, snapshot renderer, pre-commit hook running `check.sh`).
- **Next:** M2 (time math), run with `/milestone`. No draft tests exist; write them from the M2 entry. Reuse `TestSupport.swift` (`jan15Noon`, `jul15Noon`, `utc(…)`, `zone(…)`) and add new fixed instants there (e.g. the March weeks when New York and London differ by 4 h). Functions take `Zone` and `at now: Date`; `zone.timeZone` gives the `TimeZone`.
- **Open with the user:** the lightweight budget numbers in M8 (10 MB bundle, 50 MB memory) are proposals; confirm or change them. Also not yet confirmed: Dock app (not menu bar), bundle ID `com.jaredmarkowitz.worldclock`, macOS 14 minimum (see design_doc.md). `gh` isn't installed, so no GitHub CLI (CI and PRs wait on it).
- **Notes:**
  - `swift test` prints "Test run with…" twice (once per test runner); that's normal.
  - A fresh clone needs `./scripts/setup.sh` once to install the git hook.
  - `TimeZone.abbreviation(for:)` returns `GMT+9`-style text for many zones (Tokyo included), so abbreviation search only helps for zones with real abbreviations (PST, CET…). That's why it's exact-match only.
  - `TimeZone(identifier:)` accepts abbreviations (`"PST"`) and resolves `"UTC"` to `"GMT"`; `knownTimeZoneIdentifiers` (443 on this Mac) lists `GMT` but not `UTC`. `Zone` validates against that list plus `UTC`.
  - Search sorts with `localizedStandardCompare`, so order follows the user's locale; tests compare against the same call rather than a hard-coded list.

## [x] M0: Scaffold
Shared `WorldClockKit` package (Core + UI), XcodeGen project with a `WorldClockMac` target (sandboxed, ad-hoc signed), a single placeholder window, `scripts/check.sh`, and the docs (README, CLAUDE.md, ARCHITECTURE.md, design_doc.md, this roadmap). Git repo on `main`.
- Tests: `coreModuleLoads`, `uiModuleLoads`
- Done when: `./scripts/check.sh` passes; the app launches with a Dock icon and a window.

## [x] M1: Zones and search
`Zone` (a validated IANA identifier with display `city` and `region`, Codable) and `ZoneCatalog` (every known zone, with search). Search ignores case and diacritics, treats `_` and space alike, and matches city, region, full identifier, or the abbreviation in effect on a given date (PST vs. PDT; exact match only). Cities that start with the query rank first, then alphabetical order.
- Tests: `cityAndRegionComeFromIdentifier`, `nestedIdentifierUsesLastComponentAsCity`, `singleComponentIdentifierHasNoRegion`, `rejectsUnknownIdentifier`, `zoneIsCodableRoundTrip`, `decodingUnknownIdentifierFails`, `catalogListsEveryKnownZone`, `emptyQueryReturnsAllZonesSortedByCity`, `searchMatchesCityIgnoringCase`, `searchIgnoresDiacritics`, `searchTreatsUnderscoreAndSpaceAlike`, `searchMatchesRegion`, `searchMatchesFullIdentifier`, `cityPrefixMatchesRankBeforeOtherMatches`, `searchMatchesAbbreviationForThatDate`, `searchWithNoMatchIsEmpty`, plus `rejectsAbbreviationAsIdentifier`, `abbreviationMustMatchExactly`
- Done when: core tests pass.

## [ ] M2: Time math
Pure functions over `(zone, instant)`: wall-clock time, UTC offset text (`UTC−5`, `UTC+5:30`, `UTC`), offset difference between two zones (`+9 h`, `−3 h 30 min`, `Same time`), and day relation to a reference zone (yesterday / today / tomorrow). Also the reverse: turn "09:00 on this date in zone A" into an instant, handling DST gaps (skipped hour moves forward) and overlaps (repeated hour picks the first).
- Tests: offsets in winter and summer, half- and quarter-hour zones (India, Nepal), differences across DST changes (New York ↔ London differ by 4 h for part of March), date-line day relations (Kiribati ↔ Samoa), DST gap and overlap conversion.
- Done when: core tests pass.

## [ ] M3: Clock window
`ClockViewModel` (in WorldClockUI) driven by an injected clock and ticker. The ticker fires on minute boundaries, not every second (lightweight: the app should be idle between ticks). Reusable views: `TimeDisplay` (large time, date, zone name, offset), `ZonePicker` (search field + results list from M1). The Clock window shows one zone (defaults to the Mac's current zone); the chosen zone persists across launches via a `SettingsStore` protocol in Core with a UserDefaults implementation.
- Tests: view model display strings at fixed instants, minute rollover on tick, next tick scheduled for the next minute boundary, changing zone, persistence round trip, missing or corrupt saved data → defaults.
- Done when: tests pass; the window shows a live time, and picking a zone sticks after relaunch.

## [ ] M4: Compare window
A second window (Window menu, ⌘2) comparing two zones. Shows both times side by side with the difference and day relation from M2. A **time scrubber** (slider or 24-hour strip) sets a time in zone A and shows the matching time in zone B, with a "Now" button to return to live. Swap button exchanges the zones. Both zones persist.
- Tests: view model: live mode tracks now; scrubbing sets the instant from zone A's wall time; B updates; swap; Now resets; day-relation labels; persistence.
- Done when: tests pass; scheduling a call (e.g. "3 pm in New York is what in Tokyo?") takes one drag.

## [ ] M5: Desktop widget
A WidgetKit extension (`WorldClockWidget`, small and medium sizes) showing the time in one zone, chosen when the user edits the widget (`AppIntentConfiguration` with a zone parameter backed by `ZoneCatalog`). Time updates on its own via `Text(date, style: .time)` with the zone's environment, so the timeline only refreshes on day and DST changes.
- Tests: the zone entity query (search, default), timeline entry dates (next midnight, next DST transition), and widget display strings.
- Done when: tests pass; installed from /Applications, the widget appears in the macOS widget gallery, can be placed on the desktop, and shows the chosen zone's time.
- Risk: macOS may hide widgets from ad-hoc-signed apps. If so, test with a development-signed build and record the steps in README.

## [ ] M6: Settings
Settings window (⌘,): 12/24-hour time (default: follow the system), show seconds, and launch at login. Only showing seconds makes the ticker fire every second.
- Tests: settings defaults, round trip, lenient decoding (missing keys → defaults); display strings honor 12/24 h and seconds.
- Done when: tests pass; changes apply live in both windows and the widget.

## [ ] M7: Accessibility
VoiceOver labels everywhere ("Tokyo, 3:42 PM, tomorrow, 14 hours ahead"), scrubber adjustable with arrow keys, keyboard-only use of both windows, contrast meeting WCAG AA in light and dark, Increase Contrast and Reduce Transparency respected, Reduce Motion respected, no information carried by color alone (day relation and ahead/behind always have text or a symbol; any colors pass the macOS color-filter checks for red/green and blue/yellow color blindness).
- Tests: spoken text for clock and compare views.
- Done when: an Accessibility Inspector audit passes, a VoiceOver-only walkthrough works, and both windows stay readable with Display color filters on (Protanopia, Deuteranopia, Tritanopia, Grayscale) and with Increase Contrast. Snapshots render the views in an increased-contrast variant too.

## [ ] M8: Polish & packaging
Lightweight check, then the icon. App icon drawn by `scripts/make-icon.swift` (no SF Symbols in the icon: Apple's license forbids it), version 1.0.0, `scripts/install.sh` (Release build → /Applications).
- Lightweight budget (measured on the Release build, recorded in README): no third-party dependencies; app bundle under 10 MB; idle CPU near 0% with both windows open (Activity Monitor); memory under 50 MB. Fix any regressions before packaging.
- Done when: the installed app and widget run from /Applications, the icon shows in Finder and the Dock, and the lightweight budget is met.

## [ ] M9: App Store readiness
Privacy manifest, App Store entitlements (separate file if any need a provisioning profile), `scripts/release.sh` (check → bump build → archive → sign → upload → tag, as in pomodoro_timer), screenshot generator, listing draft in `docs/app-store/`, privacy policy and support pages.
- Done when: `./scripts/release.sh --local` archives, and the listing draft exists. Upload once the App Store Connect app record exists.

## Later (not scheduled)
- City aliases for search (e.g. "San Francisco" → Los Angeles), since IANA names only cover one city per zone.
- Localized city names and UI strings.
- iPhone app reusing WorldClockKit.
- More than two zones in Compare.
