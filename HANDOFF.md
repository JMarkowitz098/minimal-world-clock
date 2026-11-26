# Handoff

Rewritten in every commit, never appended. About 10 lines; history lives in git log, lessons in [docs/lessons.md](docs/lessons.md).

**Next: M12 Supporter unlock**, outlined in [docs/milestones/M12.md](docs/milestones/M12.md). It's still an outline: re-read `~/Projects/pomodoro_timer`'s M13 (follow decisions made there since), then agree each part's tests and "Done when" with the user before M12.1.

**State:** 1.0.0 (build 2) is live on the Mac App Store since 2026-11-23; App Store Connect state in [docs/app-store/listing.md](docs/app-store/listing.md) → Status. The docs were restructured on 2026-11-26 (this file, a plan-only ROADMAP.md, milestone pages, lessons, backlog, manual checks). `./scripts/check.sh` passes; run it before and after every change. Releases: `./scripts/release.sh --version 1.x.0`, then submit in App Store Connect (README → Deploying).

**Widget placeholder fix (2026-11-27):** widgets sometimes stuck on the grey placeholder because stray copies of the app were registered in LaunchServices; removed on the user's Mac, and `install.sh` now unregisters the build copies (docs/lessons.md → Widget). The user is watching it (manual check), then will replace the TestFlight copy in /Applications with the App Store build (trash the old copy first; `killall chronod` if a widget goes grey).

**Open questions:** M12's price (the user decides later). Two manual checks are open ([docs/manual-checks.md](docs/manual-checks.md)).
