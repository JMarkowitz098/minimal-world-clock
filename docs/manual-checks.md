# Manual checks

What tests and snapshots can't show: window behavior, relaunch, the widget on the desktop, the store build. Each check gives steps and what should happen. The user ticks the box and writes notes underneath; the next session reads them. When every check in a milestone has passed, its section collapses to one line under Finished milestones, and any note that needs action moves to the milestone or backlog item that will act on it.

## Finished milestones

Checked by the user; details in the milestone pages.

- **M3–M4:** live time, zone sticks after relaunch, Dock reopen, one-drag scheduling in Compare.
- **M5–M6:** widget in the gallery and on the desktop keeps its zone (development-signed); design approved in the running app; the refactor after M6 checked on the desktop.
- **M7:** Settings apply live to both windows and the widget (widget within 5–10 s).
- **M8:** Accessibility Inspector audit, VoiceOver walkthrough, color filters, Increase Contrast; widget readable in Clear and Tinted styles.
- **M9:** search and favorites in the picker and the widget's edit screen; the Mac's own 24-hour setting switching the windows live.
- **M10–M11:** installed app, icon in Finder and the Dock, lightweight budget; TestFlight build; 1.0.0 live on the store.

## Open

- [ ] **Widget at midnight and noon** (covered by tests, never seen live). Leave a widget on the desktop for a zone where midnight or noon is coming soon: at midnight its date changes to the next day; in 12-hour time, AM/PM flips at noon.
