# Backlog

Known issues and unscheduled ideas, one line each. When something is scheduled, move it into a milestone and delete it here. The requirements come first: an idea needs a clear reason from them (CLAUDE.md → Lightweight and minimal).

## Known issues

- If the Mac reports a zone missing from the system's own list (e.g. `Asia/Kolkata` vs. `Asia/Calcutta`), `ClockViewModel.live()` falls back to UTC. If a user reports it, map through the catalog by matching zone data instead.

## Ideas

- Localized city names and UI strings; Core's user-facing strings (`Same time`, `UTC`, `h`, `min`) are plain Swift strings today (M3 audit).
- iPhone app reusing WorldClockKit.
- More than two zones in Compare.
- Widget edit screen: "Favorites" / "All" sections through `IntentItemCollection` (not tried). Choosing the widget's zone in Settings instead was offered; the user said keep macOS's list "for now".
- CI and pull requests, once `gh` is installed.
