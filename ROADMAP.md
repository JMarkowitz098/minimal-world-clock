# Roadmap

The plan only: each milestone's goal and its parts, one line each. Details (tests, "Done when", notes on what was built): [docs/milestones/](docs/milestones/). Current state: [HANDOFF.md](HANDOFF.md). Unscheduled ideas: [docs/backlog.md](docs/backlog.md).

M0–M11 were built as whole milestones, one per session; from M12 on, milestones are split into parts (`M<n>.<k>`), one commit each.

## M0: Scaffold (done)
Shared package, XcodeGen project, placeholder window, `check.sh` and the docs.

## M1: Zones and search (done)
Validated IANA zones and a searchable catalog.

## M2: Time math (done)
Wall times, offsets, differences and day relations, DST gaps and overlaps.

## M3: Clock window (done)
One zone, live, ticking once a minute, saved across launches.

## M4: Compare window (done)
Two zones side by side with a time scrubber, swap and Now.

## M5: Desktop widget (done)
Small and medium widgets showing a zone chosen in the edit screen.

## M6: Design pass (done)
The look of both windows and the widget, UI speed, and a code audit.

## M7: Settings (done)
12/24-hour time, open at login and 16 color themes, live everywhere.

## M8: Accessibility (done)
VoiceOver, keyboard use, WCAG AA contrast, Increase Contrast, Reduce Motion.

## M9: Pre-release features (done)
Wider zone search, favorites and 24-hour time.

## M10: Polish & packaging (done)
Lightweight budget, app icon, version 1.0.0, install script.

## M11: App Store readiness (done)
Privacy manifests, release script, screenshots, listing and web pages.

## M12: Supporter unlock
A gentle daily reminder and a one-time purchase that removes it; every feature stays free.
- [ ] M12.1 Reminder schedule
- [ ] M12.2 Entitlements and StoreKit
- [ ] M12.3 Reminder card
- [ ] M12.4 App Store Connect and release 1.1.0
