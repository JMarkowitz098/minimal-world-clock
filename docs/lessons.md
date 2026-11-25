# Lessons

Non-obvious findings (API quirks, gotchas, dead ends), grouped by topic, with the milestone that found them. Read the sections a task touches; add to them. **Don't retry** marks things already tried that didn't work.

## Working from the agent's shell

- Scripted keyboard and click tests (System Events, AX) drive the user's **real** app and screen: ask first, keep runs short, and never send keys that could reach the zone picker. An M8 run changed Compare's zone B (Paris → Abidjan) and a run in M6 sent keys elsewhere while the user was working.
- System Events sees no windows until the app is activated (`tell application … to activate`); `CGWindowListCopyWindowInfo` sees them right away. System Events' `click` on an element can click its screen position instead of pressing it: use `AXUIElementPerformAction(kAXPressAction)`.
- Reading the AX tree works with a small Swift tool using `AXUIElementCopyAttributeValue` (the shell is trusted for Accessibility): roles, labels (`AXDescription`), values, `AXValueDescription` (what VoiceOver reads for a slider) and frames. AppleScript's `description`/`entire contents` returned nothing useful. The app must be frontmost for its windows to be listed. AX doesn't report SwiftUI's own keyboard focus, so check key handling by its effect (e.g. a text field appearing). (M8)
- The shell can't read the sandboxed app's preferences (`~/Library/Containers/com.jaredmarkowitz.minimalworldclock/Data/Library` is "Operation not permitted"), so `defaults delete … "NSWindow Frame clock"` silently does nothing from here: ask the user to run it, or reason from `CGWindowListCopyWindowInfo` sizes. `screencapture -l` of a window also fails (no screen-recording permission). (M6)
- `log show` returns nothing in the agent's shell, and a development-signed widget's container can't be read by other processes, so a debug log file there only works for ad-hoc builds. (M5)
- Measuring a running app: `top -l 13 -s 5 -pid <pid> -stats pid,cpu,idlew,power,mem,threads` for CPU, idle wakeups and power (Activity Monitor's Energy Impact), `footprint <pid>` for memory, `lipo -info` for architectures. All work against the user's running app. (M10)
- Measuring screenshots pixel by pixel (a small Swift script with `NSBitmapImageRep.colorAt`) found the widget's edge highlight and centering offset. (M6)
- BSD `sed` has no `\b`: a rename with it silently matched nothing. (M7)
- `gh` (GitHub CLI) is installed and logged in as of 2026-11-26.
- `swift test` prints "Test run with…" twice (once per test runner); that's normal.

## Signing and App Groups

- **Ad-hoc signing breaks the widget's configuration:** an ad-hoc build puts the widget in the gallery, draws it and opens its edit screen, but macOS silently drops the zone the user picks (the provider always gets `nil`; `entities(for:)` is never called). Signed with the Apple Development certificate (team Y7W4DC22F6) it works. Found by changing one thing per build. Not documented by Apple; closest report: macOS 27 refuses App Group containers to ad-hoc apps (github.com/frankydzoro/Limitwick/issues/8). Guarded by a "Require team signing" build step and `check.sh`. (M5)
- Not the cause (**don't retry**): optional parameter vs. `defaultResult()`, IDs containing `/`, the module name, the bundle ID. (M5)
- The first development-signed install over an ad-hoc one still failed; a later one worked. Replacing a differently signed copy can leave stale widget state until `killall chronod`. After changing signing, remove and re-add the widget before judging. (M5)
- App Group: the team-ID-prefixed form works with manual development signing and no provisioning profile. The `group.` form would need a profile and can trigger macOS 15's "would like to access data from other apps" prompt (developer.apple.com/forums/thread/758375). If settings ever stop carrying over in a store build, start from Quinn's "App Groups: macOS vs iOS" forum post. (M7, M11)

## Widget

- **Reinstalling doesn't restart the widget:** the running extension keeps the old code after the app in /Applications is replaced, and removing and re-adding the widget doesn't restart it. `pkill -x MinimalWorldClockWidget` after installing; if macOS relaunches it in the same second the copy lands, it may load the old binary: kill it once more. Check with `ps -axo pid,lstart,command | grep MinimalWorldClockWidget` (start time vs. the binary's `stat`). (M6)
- Xcode registers the copy in `build/` too; `pluginkit -r <path to .appex>` unregisters it so only /Applications' copy is live. (M5)
- `Text(date, style: .time)` draws a fixed time; a widget clock that updates itself needs `Text(.currentDate, format:)` (macOS 15+). `Text(_:format:)` formats in the environment's `\.timeZone` and `\.locale`, ignoring the format style's: `ZoneWidgetView` sets both. Snapshots of the Mac's own zone hide such bugs, so widget snapshots include other zones. (M5, M7)
- **The widget's time must use a system format:** a custom `DiscreteFormatStyle` left the widget on its redacted placeholder, even after re-adding it and restarting `chronod`. The system draws the widget from an archived view and apparently can't use our own format types. So the windows draw AM/PM smaller and the widget doesn't. (M6)
- On the desktop a live `Text` takes all the width it can, so the live hours and minutes are drawn over a hidden fixed copy (`WidgetDisplay.timeText`) and AM/PM is fixed text; the timeline refreshes at midnight, noon, DST and when the hour gains or loses a digit. Which of these the centering needed is unknown (the stale extension process hid every attempt); all stay. The small widget's time has `.offset(y: 5)`: its text box keeps room for descenders. (M6)
- macOS draws a one-pixel light line along the top and bottom edges of every desktop widget (Apple's Weather has it too); a border at the edge shows it as a gap. No macOS API removes it (`widgetTexture` is visionOS-only in the macOS 27.2 SDK). (M6)
- **Widget edit screen speed (measured with the user):** the pause before the zone list appears is macOS's; Apple's World Clock widget pauses just as long. Our work there takes ~4 ms cold. **Don't retry:** suggesting 15 zones instead of all, capping search at 50 results, a Release build. (M6)
- Widget reload delay after a Settings change (5–10 s): `reloadAllTimelines()` is a request to chronod; there are reports of delays and ignored reloads (forums thread 760621, github.com/cbusillo/context-panel/issues/775). Our extension's work is milliseconds. (M7)
- Xcode 27 requires every `WidgetConfigurationIntent` parameter to be optional. Apple's World Clock widget's extension is also `WorldClockWidget`, hence our "Minimal…" names. (M5)
- The app target's build prints "Metadata extraction skipped, no AppIntents.framework dependency found": harmless (`check.sh` filters it). (M5)
- VoiceOver: macOS names every desktop widget's container itself ("Minimal World Clock widget"); labeling our content as a container only added a group inside (tried and reverted). VO+Shift+↓ reads city, date and time. (M8)

## Windows and SwiftUI on macOS

- A SwiftUI app whose only scene is a `Window` quits when it closes. `applicationShouldTerminateAfterLastWindowClosed` returns `false`, and SwiftUI then reopens the `Window` on a Dock click by itself. (M3)
- **Hidden title bar:** macOS sizes a `.hiddenTitleBar` window as content + title bar, with the title bar as a top safe area; `ignoresSafeArea` on the whole content leaves an empty band. So the content respects the safe area and only the background and the top strip extend into it. Snapshots simulate the strip with `.safeAreaPadding(.top, 28)`. (M6)
- **Resizable windows:** an invisible copy at scale 1 gives the natural size; the visible copy scales. `WindowAspectRatio` sets `NSWindow.contentAspectRatio` and fits a restored frame to it (AppKit enforces the ratio only while dragging). `.defaultSize(200×100)` is below the natural size so a new window opens at exactly its natural size. (M6)
- A `Window` with a `Slider` opens 900 pt wide (the slider's ideal width); `frame(idealWidth:)` doesn't change that, `.defaultSize` on the scene does. macOS autosaves window frames (`NSWindow Frame compare`); delete that key before checking a default-size change, never the whole defaults domain (it wipes the saved zones). (M4)
- A slider with `step:` draws a tick per step on macOS; `CompareView` rounds in the binding instead. (M4)
- Dragging: `windowBackgroundDragBehavior(.enabled)` didn't move the window when dragging the time (content covers the background); `.gesture(WindowDragGesture())` + `.allowsWindowActivationEvents(true)` does. (M6)
- The hover edge uses `ConcentricRectangle` (macOS 26+) to follow the window's corners; it has no `strokeBorder`, so it's stroked at 4 pt and the window clips half. `.tint` colors a TextField's cursor. The List's scroll bar and the text selection color can't be themed. (M6)
- A `.focusable()` view gets the system focus rectangle once clicked; `TimeStrip` uses `.focusEffectDisabled()` and draws its own ring. (M6)
- Focusing a just-inserted `TextField` with `.task { isFocused = true }` sets focus in AX but keys go nowhere until a second click; `.onAppear { DispatchQueue.main.async { isFocused = true } }` works. A `TextField` can't draw AM/PM smaller, so `EditableTime` draws typed text at 80% in a box sized to the larger of typed and shown time. (M6)
- In a plain macOS `List`, `listSectionSeparator`/`listSectionSeparatorTint` had no visible effect; the line under the favorites is the last favorite row's `listRowSeparatorTint`. (M9)
- `.themed(_:)` also sets `.preferredColorScheme` from `Theme.isDark`, so a dark theme's controls are dark in Light mode. The Settings window isn't themed. (M7)
- `scenePhase` doesn't report a minimized window on macOS; `NSWindow.occlusionState` (`WindowVisibility.swift`) also covers covered windows, other Spaces, a hidden app and a sleeping display. (M10)
- `NotificationCenter`'s block observer can't be removed from a `deinit` under Swift 6 (non-Sendable token); `WindowVisibility` uses a selector observer, which the center drops on deallocation. (M10)
- `DispatchTicker` uses `asyncAfter(wallDeadline:)`, which keeps counting while the Mac sleeps; `Timer` and `Task.sleep` use uptime clocks and would fire late after wake. (M3)
- On macOS 26+ an old-style icon that doesn't fit the rounded shape is boxed in a gray tile. An icon drawn on Apple's template (824-point body, ~185-point corners) shows in the system's shape with its glass edge; no Icon Composer `.icon` needed. Check with `NSWorkspace.shared.icon(forFile:)` rendered to PNG. (M10)

## Accessibility

- Accessibility Inspector's audit sometimes reports "Contrast failed … 1.00" with both colors the background (different text each run). The frames are right and the Color Contrast Calculator measured 5.6:1, so these are capture misses. "Element has no description" on SwiftUI's hosting view is real: fixed with `WindowAccessibilityName` (`.accessibilityLabel` only names a new group inside it). (M8)
- The audit and the Inspector need the target app chosen in the "Mac ›" breadcrumb at the top left, and the window to audit in front. (M8)
- `\.colorSchemeContrast` follows the Mac's Increase Contrast in the app; offscreen snapshots need `\._colorSchemeContrast` (the high-contrast `NSAppearance` alone didn't reach SwiftUI). (M8)
- On macOS, clicking doesn't move the VoiceOver cursor; VoiceOver starts a window at its first control (the city button), then VO+→ reaches the time. Putting the time first made VO+→ from the button go nowhere (reverted). (M8)
- Contrast math: macOS blends a translucent fill with the gamma-encoded sRGB values; blending linear light read hovered states on dark themes 0.4 lower. (M8)

## Time zones, locales and Foundation

- The system catalog uses old IANA names, sometimes only those: `Asia/Calcutta` (not `Asia/Kolkata`), `Asia/Ho_Chi_Minh` but no `Asia/Saigon`, both `Europe/Kiev` and `Europe/Kyiv`; `Etc/GMT±N` zones aren't listed (only `GMT`). `zone.tab` uses today's names, so `make-zone-names.swift` maps the old ones by hand. `zone(…)` in tests traps on unknown identifiers: check with `TimeZone.knownTimeZoneIdentifiers` first. (M1, M9)
- `TimeZone(identifier:)` accepts abbreviations (`"PST"`) and resolves `"UTC"` to `"GMT"`; `knownTimeZoneIdentifiers` (443 here) lists `GMT` but not `UTC`. `Zone` validates against that list plus `UTC`. (M1)
- `TimeZone.abbreviation(for:)` returns `GMT+9`-style text for many zones, so abbreviation search is exact-match only. (M1)
- Foundation's generic zone names cover far fewer zones than expected: "Pacific Time" is only Los Angeles, Tijuana, Santa Isabel; most zones get a country or city name. Asking for 3 names × 443 zones takes ~30 ms per process, hence the generated `ZoneNames.swift`. (M9)
- `instant(for:)` samples the zone's offset around the wall time, keeps the candidates that read back as that wall time (earliest wins), and in a gap uses the pre-jump offset. It doesn't use `Calendar.date(from:)`, whose gap and overlap behavior isn't documented. Scrubbing into a DST gap makes the thumb jump forward an hour: intended. (M2, M4)
- en_US time text has a narrow no-break space (U+202F) before AM/PM; tests use `nnbsp`. Time uses the `jmm` template, so 12/24 h follows the locale. (M3)
- 12/24-hour is a locale tweak (`Locale.applying`: `Locale.Components.hourCycle`, giving `en_US@hours=h23`); `Date.FormatStyle`, `DateFormatter` templates and the `j` check all honor it. Our enum is `TimeFormat` because `HourCycle` collides with `Locale.HourCycle`. (M7)
- Search sorts with `localizedStandardCompare`, so tests compare against the same call rather than a hard-coded list. (M1)
- `JSONEncoder` escapes `/` (`"Asia\/Tokyo"`), same as the old `Zone` encoding, so `Place` stays byte-compatible. (M9)
- A favorite is listed when its zone matches the query (a San Francisco favorite shows for "los"); a result equal to a favorite isn't listed again, but a different city in the same zone is. (M9)

## Snapshots

- `ImageRenderer` draws AppKit-backed controls (TextField, List, Slider) as yellow placeholders; the tool draws through an offscreen `NSHostingView` + `cacheDisplay` instead. (M3)
- `ClockView`/`CompareView` set the hosting window's aspect ratio, which resizes the offscreen window, and a window taller than the screen gets clamped; both shift the render. Option sheets draw static mocks and stay under ~650 pt tall. (M7)
- Hover can't be snapshotted: to preview Compare's hover states, temporarily set `isHovered`/`hoverMinute`'s initial values, render, and revert. (M6)
- App Store screenshots render each window to its own bitmap and place the image (on a 1440×900 canvas the windows would reshape it). `scaleEffect` on a widget blurred it; widgets render at 2.5× and show at 1.25×. (M11)
- The longest city name in the catalog is "Bahia Banderas" (`clock-long-name`). (M3)

## Packaging and release

- `xcodebuild` without `-destination` builds only the Mac's architecture (3.7 MB); `generic/platform=macOS` gives the universal app (7.6 MB) the App Store gets (the Mac App Store doesn't thin). (M10)
- An install script that pipes `xcodebuild` into `grep … || true` hides a failed build and installs a stale copy (pomodoro_timer's did); ours logs to `build/install.log` and stops. (M10)
- Each bundle needs its own privacy manifest. UserDefaults is the only required-reason API used: CA92.1 for the app's own defaults, 1C8F.1 for the App Group. The first incremental `xcodebuild` after `xcodegen` left the widget's copy out; a second build included it (`check.sh`'s guard catches a miss). (M11)
- No separate App Store entitlements file: nothing needs a provisioning profile (proven by the first upload). (M11)
- TestFlight on a Mac with the development copy in /Applications installs beside it as "Minimal World Clock 2.app"; the widget registers from that copy. Check which copy is live with `pluginkit -m -v -p com.apple.widgetkit-extension | grep worldclock` (shows the path) and `codesign -dv --verbose=2 <app>` (Authority). Don't run `install.sh` while testing a TestFlight build: it re-registers the development widget. (M11)
- The portfolio site builds locally with `npx @11ty/eleventy` (output in `_site/`); `npm start` serves it. (M11)
