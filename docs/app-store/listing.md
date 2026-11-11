# App Store listing: Minimal World Clock

Draft (M11). Fields as they appear in App Store Connect; character limits are in brackets. Modeled on `~/Projects/pomodoro_timer/docs/app-store/listing.md`, which shipped.

## App information

| Field | Value |
|---|---|
| Name [30] | Minimal World Clock (App Store names are unique: confirm it's free when creating the app record) |
| Subtitle [30] | Time zones, simply |
| Bundle ID | com.jaredmarkowitz.minimalworldclock |
| SKU | MINIMAL-WORLD-CLOCK-MAC |
| Primary category | Utilities |
| Secondary category | Productivity |
| Age rating | 4+ (answer "No" or "None" to every questionnaire item; age category "Not Applicable") |
| Content rights | No third-party content (the color palettes are MIT-licensed and credited in the About window) |
| Copyright | 2026 Jared Markowitz |
| Price | Free (the supporter unlock, M12, arrives in a later version), base country United States |
| Availability | All countries or regions |
| EU trader status | Not a trader (account-wide, under Business; must change before selling anything) |
| Version release | Automatically after approval |
| Privacy policy URL | https://www.jaredmarkowitz.com/apps/world-clock/privacy |
| Support URL | https://www.jaredmarkowitz.com/apps/world-clock/support |
| Marketing URL (optional) | https://www.jaredmarkowitz.com/apps/world-clock |

The privacy, support and marketing pages live in the portfolio repo (`~/Projects/portfolio/apps/world-clock/`); pushing its `master` deploys them.

## App Privacy

Select **"Data Not Collected"**, then click **Publish** (required before submitting). The app has no analytics, accounts, ads, or network access. Settings, cities and favorites stay on the Mac (the app's container and an App Group shared with the widget). The privacy manifests (`Apps/*/PrivacyInfo.xcprivacy`) say the same.

## App Accessibility

Mac: VoiceOver, Dark Interface (the dark themes, and a dark theme gives the windows macOS's dark controls), Differentiate Without Color Alone, Sufficient Contrast (every theme passes WCAG AA, tested), Reduced Motion. Not Voice Control or Larger Text (untested), and Captions and Audio Descriptions don't apply. Fill in as a draft; Apple only allows **Publish** once a version is live.

## App Review contact

Sign-in required: off (no accounts). Contact: Jared Markowitz, apps@jaredmarkowitz.com, and a phone number in international format (with "+" and country code, or Save fails).

## Promotional text [170]

A calm, minimal world clock for your Mac: the time in any city, a quick way to compare two time zones, and widgets for your desktop.

## Description [4000]

Minimal World Clock does three things and keeps them simple: a clock window for any city, a window that compares two time zones, and widgets that keep a city's time on your desktop.

CLOCK
• The time and date in any city, in large, easy-to-read type
• Resize the window and the clock grows with it
• Search by city, country, or time zone name: "San Francisco", "Japan", "Pacific Time"
• Star the cities you use most to keep them at the top of the list

COMPARE
• Two cities side by side, with the difference between them
• Drag across the day to see the time in both places, or type a time
• Shows when the other city is already on the next day
• Swap the cities with one click

WIDGETS
• Small and medium desktop widgets, each with its own city
• They keep time on their own, even when the app is closed

MAKE IT YOURS
• Sixteen color themes, from Solarized and Nord to an amber CRT
• 12- or 24-hour time
• Open at login

LIGHT AND PRIVATE
• Updates once a minute, and pauses while its windows are hidden
• No accounts, no ads, no tracking. Nothing leaves your Mac.

ACCESSIBLE
• Works with VoiceOver, never relies on color alone, and every theme meets contrast guidelines
• Follows Increase Contrast and Reduce Motion

## Keywords [100]

time zone,timezone,converter,meeting planner,utc,gmt,widget,city,travel,remote,team,international

(Words already in the name or subtitle are indexed automatically, so they aren't repeated here. 97 characters.)

## Screenshots

`docs/app-store/screenshots/` (2880×1800, an accepted Mac size): `1-clock`, `2-compare`, `3-search`, `4-themes`. Drawn from the real views with fixed times and cities; regenerate after a UI change with:

    swift run --package-path Tools/Snapshots Snapshots --app-store

The shots are defined in `Tools/Snapshots/Sources/Snapshots/AppStore.swift`.

## Notes for App Review

Minimal World Clock is a regular windowed app with a Dock icon. It opens the Clock window; click the city name at its top right to choose another city. The Compare window is under **Window → Compare** (⌘2) and Settings under **Minimal World Clock → Settings…** (⌘,). Closing the Clock window leaves the app running; click the Dock icon to reopen it.

The desktop widget: right-click the desktop → **Edit Widgets…** → search "Minimal World Clock". Right-click a placed widget → **Edit "Minimal World Clock"** to choose its city. The widget reads the theme and time format chosen in Settings through an App Group shared with the app.

Open at login is off by default and only enabled by the user (Settings). The app makes no network connections.
