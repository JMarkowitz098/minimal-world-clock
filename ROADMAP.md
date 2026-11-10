# Roadmap

Each milestone fits in one session. Its "Tests" are the acceptance criteria: write them first (TDD). "Done when" is the check before committing (see CLAUDE.md → Git). **Stop after each milestone and check in before starting the next.**

Shared commands: `./scripts/check.sh` (all tests + app build). Use `swift test --package-path Packages/WorldClockKit` for fast TDD loops.

## Handoff (read first; rewrite at the end of every session)

Each milestone runs in a new chat, so this section carries what the next session needs and the code and git history can't show.

- **Last session (2026-11-10):** M2 done: `WallTime.swift`, `Offsets.swift`, `DayRelation.swift` in `WorldClockCore` (40 package tests green). The user also added a requirement mid-session: a non-intrusive prompt asking users to buy the app, like pomodoro_timer's planned M13. Recorded in `design_doc.md` and scheduled as **M10** (after v1.0 ships, as pomodoro did).
- **Next:** M3 (Clock window), run with `/milestone`. Build display strings from the M2 functions (`wallTime`, `utcOffsetText`); use `DateFormatter` with `timeZone = zone.timeZone` for localized time text. Inject the clock (`() -> Date`) and the ticker; the next tick is at the next minute boundary.
- **Confirmed by the user:** Dock app; bundle ID `com.jaredmarkowitz.worldclock`; macOS 14 minimum; the M8 lightweight budget; minimal UI matters a lot (they find existing clock apps too feature-heavy), so keep every view to what its milestone needs.
- **Open with the user (not blocking M3–M9):**
  - M10 purchase reminder: popup window or a small card inside the Clock window? How often (pomodoro's plan: at most once a day, after a few days of use)? Ask on first launch (risks bad reviews)? Price? Ship v1.0 free without it (current plan) or include it in 1.0?
  - `gh` isn't installed, so no GitHub CLI (CI and PRs wait on it).
- **Notes:**
  - `swift test` prints "Test run with…" twice (once per test runner); that's normal.
  - A fresh clone needs `./scripts/setup.sh` once to install the git hook.
  - The system catalog uses old IANA names: `Asia/Calcutta` (not `Asia/Kolkata`), and `Etc/GMT±N` zones are not listed (only `GMT`). `zone(…)` in tests traps on unknown identifiers, so check names with `TimeZone.knownTimeZoneIdentifiers` first.
  - `TimeZone.abbreviation(for:)` returns `GMT+9`-style text for many zones (Tokyo included), so abbreviation search only helps for zones with real abbreviations (PST, CET…). That's why it's exact-match only.
  - `TimeZone(identifier:)` accepts abbreviations (`"PST"`) and resolves `"UTC"` to `"GMT"`; `knownTimeZoneIdentifiers` (443 on this Mac) lists `GMT` but not `UTC`. `Zone` validates against that list plus `UTC`.
  - Search sorts with `localizedStandardCompare`, so order follows the user's locale; tests compare against the same call rather than a hard-coded list.
  - `instant(for:)` samples the zone's offset around the wall time, keeps the candidates that read back as that wall time (earliest wins), and in a gap uses the smaller (pre-jump) offset. It doesn't use `Calendar.date(from:)`, whose gap and overlap behavior isn't documented.

## [x] M0: Scaffold
Shared `WorldClockKit` package (Core + UI), XcodeGen project with a `WorldClockMac` target (sandboxed, ad-hoc signed), a single placeholder window, `scripts/check.sh`, and the docs (README, CLAUDE.md, ARCHITECTURE.md, design_doc.md, this roadmap). Git repo on `main`.
- Tests: `coreModuleLoads`, `uiModuleLoads`
- Done when: `./scripts/check.sh` passes; the app launches with a Dock icon and a window.

## [x] M1: Zones and search
`Zone` (a validated IANA identifier with display `city` and `region`, Codable) and `ZoneCatalog` (every known zone, with search). Search ignores case and diacritics, treats `_` and space alike, and matches city, region, full identifier, or the abbreviation in effect on a given date (PST vs. PDT; exact match only). Cities that start with the query rank first, then alphabetical order.
- Tests: `cityAndRegionComeFromIdentifier`, `nestedIdentifierUsesLastComponentAsCity`, `singleComponentIdentifierHasNoRegion`, `rejectsUnknownIdentifier`, `zoneIsCodableRoundTrip`, `decodingUnknownIdentifierFails`, `catalogListsEveryKnownZone`, `emptyQueryReturnsAllZonesSortedByCity`, `searchMatchesCityIgnoringCase`, `searchIgnoresDiacritics`, `searchTreatsUnderscoreAndSpaceAlike`, `searchMatchesRegion`, `searchMatchesFullIdentifier`, `cityPrefixMatchesRankBeforeOtherMatches`, `searchMatchesAbbreviationForThatDate`, `searchWithNoMatchIsEmpty`, plus `rejectsAbbreviationAsIdentifier`, `abbreviationMustMatchExactly`
- Done when: core tests pass.

## [x] M2: Time math
Pure functions on `Zone` taking `at now: Date`: `wallTime(at:)`, `utcOffset`/`utcOffsetText` (`UTC−5`, `UTC+5:30`, `UTC`), `offset`/`offsetText(from:at:)` (`+9 h`, `−3 h 30 min`, `+15 min`, `Same time`), and `dayRelation(from:at:)` (yesterday / today / tomorrow, or `.days(±2)` for zones 25 h apart). The reverse, `instant(for: WallTime)`, handles DST gaps (skipped time moves forward) and overlaps (repeated time picks the first).
- Tests: `utcOffsetTextInWinterAndSummer`, `utcOffsetTextForUTCIsPlain`, `utcOffsetTextForHalfAndQuarterHourZones`, `differenceTextInWholeHours`, `differenceTextWithMinutes`, `differenceTextUnderAnHour`, `differenceTextSameTime`, `differenceChangesAcrossDSTTransitions` (New York ↔ London 4 h apart in March and late October), `differenceFlipsAcrossHemispheres`, `wallTimeInZone`, `wallTimeKeepsSeconds`, `instantFromWallTime`, `dstGapMovesForward`, `dstGapMovesForwardInLondon`, `dstOverlapPicksFirst`, `skippedDayMovesForward` (Samoa, 2011), `sameZoneIsToday`, `dayRelationChangesAtMidnight`, `kiribatiIsTomorrowFromAmericanSamoa`, `samoaAndAmericanSamoaShareClockTimeButNotDate`, `extremeZonesCanBeTwoDaysApart`
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
- Lightweight budget (measured on the Release build, recorded in README): no third-party dependencies; app bundle under 10 MB; idle CPU near 0% and Energy Impact low with both windows open (Activity Monitor → CPU and Energy tabs); no timer activity while windows are hidden or minimized; memory under 50 MB. Fix any regressions before packaging.
- Done when: the installed app and widget run from /Applications, the icon shows in Finder and the Dock, and the lightweight budget is met.

## [ ] M9: App Store readiness
Privacy manifest, App Store entitlements (separate file if any need a provisioning profile), `scripts/release.sh` (check → bump build → archive → sign → upload → tag, as in pomodoro_timer), screenshot generator, listing draft in `docs/app-store/`, privacy policy and support pages.
- Done when: `./scripts/release.sh --local` archives, and the listing draft exists. Upload once the App Store Connect app record exists.

## [ ] M10: Supporter unlock (purchase reminder)
Requirement added 2026-11-10: a non-intrusive prompt asking users to buy the app, like pomodoro_timer's planned M13. The app stays fully functional; a one-time in-app purchase (StoreKit 2, non-consumable, price to decide) removes the reminder for good. No feature paywall.
- Design (to confirm with the user before starting): a gentle reminder at most once a day, starting after a few days of use; one-click "Not now"; Restore Purchase for reinstalls; never steals focus while the user is mid-scrub in Compare. Easy dismissal is also an App Review requirement.
- `Entitlements` protocol in Core with a fake for tests; reminder scheduling logic test-first; StoreKit configuration file for local testing.
- Tests: reminder schedule (grace period, at most once a day, never after purchase), purchase and restore through the fake entitlements, lenient decoding of the saved reminder state.
- Done when: tests pass; with the StoreKit test configuration, buying removes the reminder and it stays gone after relaunch.

## Later (not scheduled)
- City aliases for search (e.g. "San Francisco" → Los Angeles), since IANA names only cover one city per zone.
- Localized city names and UI strings.
- iPhone app reusing WorldClockKit.
- More than two zones in Compare.
