---
name: milestone
description: Run one ROADMAP.md milestone from start to finish in a fresh session - read the handoff, TDD the listed tests, verify (including UI snapshots), update docs and the handoff, commit, push, and stop to check in. Use when the user says "start M<n>", "next milestone", or /milestone.
---

# Run a milestone

One milestone per session. The user starts a new chat for each, so the repo is the only memory.

## 1. Orient
1. Read `ROADMAP.md`: the **Handoff** section first, then the milestone (the one named in the args, otherwise the first unchecked one).
2. Read `CLAUDE.md` and the parts of `ARCHITECTURE.md` and `design_doc.md` the milestone touches.
3. Run `./scripts/check.sh`. It must pass before you change anything; if it doesn't, stop and tell the user.
4. If the Handoff lists open questions that block this milestone, ask them now (one message, all at once).
5. Briefly tell the user the plan: files to add, the tests, and anything in the milestone you think is ambiguous or wrong.

## 2. Build test-first
For each behavior in the milestone's **Tests** list (test names are the acceptance criteria; keep them):
1. Write the failing test (Swift Testing: `@Test`, `#expect`). Run `swift test --package-path Packages/WorldClockKit` and confirm it fails for the right reason.
2. Write the least code that passes.
3. Refactor with the tests green.

Follow CLAUDE.md → Rules (Core is Foundation-only, time is injected, no `TimeZone.current` in tests, small views fed by a view model). If you add or remove files under `Apps/`, run `xcodegen generate`.

## 3. Verify
1. `./scripts/check.sh` passes (warnings fail it).
2. **UI changes:** add or update entries in `Tools/Snapshots/Sources/Snapshots/Catalog.swift` (fixed dates and zones), run `swift run --package-path Tools/Snapshots Snapshots [name]`, and Read the PNGs in `build/snapshots/` (light and dark). Fix what looks wrong: clipping, alignment, contrast, dark mode.
3. **Running app:** for behavior a snapshot can't show (windows, menus, persistence across relaunch, widgets), build and launch it, then ask the user to check the specific things listed under the milestone's "Done when".

## 4. Hand off
1. Check the milestone off in `ROADMAP.md` (`[x]`) and fix its text if what was built differs.
2. Update `ARCHITECTURE.md` (file map, invariants, recipes) and `design_doc.md` (product decisions made this session).
3. **Rewrite ROADMAP.md → Handoff:** last session's result, exactly what the next milestone should start with, open questions for the user, and non-obvious lessons (gotchas, dead ends, API quirks). Remove stale entries. Unfinished work goes in `docs/handoff/`, never only in chat.
4. Commit as `M<n>: <title>` with a short body (the pre-commit hook runs `check.sh`), then `git push`.

## 5. Stop
Report to the user: what was built, how it was verified, anything they should look at themselves, and the open questions. Do **not** start the next milestone.
