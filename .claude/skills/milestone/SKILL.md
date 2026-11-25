---
name: milestone
description: Work through a milestone one small part at a time - orient from HANDOFF.md, check in with the user before building, TDD the part's tests, verify (including UI snapshots), update the docs and HANDOFF.md, commit, push, and ask whether to continue. Use when the user says "start M<n>", "next part", "continue", or /milestone.
---

# Run a milestone, one part at a time

Milestones are split into parts (`M<n>.<k>`). One part = one commit = one idea the user can review in about 10–15 minutes. The repo is the only memory between sessions, so the docs are updated in every commit.

## Where things go
- `ROADMAP.md`: the plan only. Each milestone has a one-sentence goal and a checklist of parts, one short line each. No tests, notes, dates or history.
- `docs/milestones/M<n>.md`: the working detail for each part: what it covers, its **Tests**, **Done when**, and a short **Note (built)** when the build differs from the plan.
- `HANDOFF.md`: the current state: what's next, what blocks it, open questions. **Rewrite it each time, never append**; about 10 lines, no history (git log has it).
- `docs/lessons.md`: non-obvious findings (API quirks, gotchas, dead ends) by topic.
- `docs/manual-checks.md`: steps the user checks in the running app or on the desktop.
- `docs/backlog.md`: known issues and unscheduled ideas, one line each.
- `design_doc.md`: product decisions and their reasons. `ARCHITECTURE.md`: the code as it is. Commit bodies: what happened.

## 1. Orient
1. Read `HANDOFF.md`, then the part's section in `docs/milestones/M<n>.md` (the part named in the args, otherwise the first unchecked part in `ROADMAP.md`).
2. Read `CLAUDE.md`, and the sections of `ARCHITECTURE.md`, `design_doc.md` and `docs/lessons.md` the part touches. Read `docs/manual-checks.md` for the user's latest results.
3. Run `./scripts/check.sh`. It must pass before you change anything; if it doesn't, stop and tell the user.
4. If HANDOFF.md lists a question that blocks the part, ask now (one message, all at once).
5. **Too big?** If the part won't fit one reviewable commit (roughly 300 changed lines of our code, not counting docs, snapshots or generated files, or more than one new idea), propose splitting it before starting.
6. **Check in before building (STOP).** The part was planned before the code it builds on existed, so review it with the user first:
   - **A milestone that's still an outline** (its first part, with no Tests or "Done when" yet): propose the detail for the whole milestone: each part's tests and "Done when". Write it into `docs/milestones/M<n>.md` once agreed.
   - **Every part:** check it against what has changed since it was written: code built since, manual-check results, decisions in design_doc.md, backlog items. Say what still fits and what you'd change (scope, tests, order, a split), with a recommendation.
   - Then give the plan in a few lines: files you will add or change, the tests, and anything unclear or wrong.
   - **Wait for the user's go-ahead** before building. Changes agreed here go into the docs in this part's commit.

## 2. Build test-first
For each name in the part's **Tests** (test names are the acceptance criteria; keep them):
1. Write the failing test (Swift Testing: `@Test`, `#expect`). Run `swift test --package-path Packages/WorldClockKit` and confirm it fails for the right reason.
2. Write the least code that passes.
3. Refactor with the tests green.

Follow CLAUDE.md → Rules (Core is Foundation-only, time is injected, no `TimeZone.current` in tests, small views fed by a view model). If you add or remove files under `Apps/`, run `xcodegen generate`. Debugging starts from Apple's docs and searches for similar reports (and `docs/lessons.md`), not repeated experimental builds the user has to retest. Visual design choices go to the user as rendered option sheets (`Prototypes.swift`).

## 3. Verify
1. `./scripts/check.sh` passes (warnings fail it).
2. **UI changes:** add or update entries in `Tools/Snapshots/Sources/Snapshots/Catalog.swift` (fixed dates and zones), run `swift run --package-path Tools/Snapshots Snapshots [name]`, and Read the PNGs in `build/snapshots/` (light and dark). Fix what looks wrong: clipping, alignment, contrast, dark mode.
3. **Things a snapshot can't show** (windows, menus, relaunch, the widget on the desktop, purchases) go in `docs/manual-checks.md` as steps for the user: what to do and what should happen. Build and launch the app when that helps, and tell the user what to check.

## 4. Update the docs (every commit)
Every commit leaves the docs describing the code **as it is after that commit**, not as planned:
- `ROADMAP.md`: tick the part (`[x]`). Change a line only if the part itself changed. The milestone's last part also adds `(done)` to its heading.
- `docs/milestones/M<n>.md`: if the build differs from the plan, add a short **Note (built)** under the part saying how and why. Calls made without asking the user go there too, marked as such.
- `HANDOFF.md`: rewrite it for the next part.
- `ARCHITECTURE.md`: file map, invariants and recipes for anything added, moved or removed; one line per file, never a list of its functions.
- As needed: `README.md` (for humans) and `CLAUDE.md` → Commands (new or changed commands, scripts, setup steps), `CLAUDE.md` → Rules (new conventions), `design_doc.md` (product decisions or scope changes), `docs/lessons.md` (gotchas found), `docs/backlog.md` (issues found but not fixed), `docs/app-store/` (listing or App Store Connect changes).

Then read `git diff` and ask: would a fresh session reading only the docs be misled? If so, fix the docs.

## 5. Commit
1. Stage only the files that belong to the part; commit as `M<n>.<k>: <title>` with a short body saying what was done and anything that differed from the plan (the pre-commit hook runs `check.sh`).
2. `git push`.

## 6. After the commit
Report in a few lines: what was built, how it was verified, anything for the user to check (manual checks), and the open questions. Then ask whether to continue to the next part in this session or stop. When the milestone's last part is committed, also give a short summary of the whole milestone.
