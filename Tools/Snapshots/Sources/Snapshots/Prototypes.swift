import SwiftUI

/// Temporary design option sheets (ARCHITECTURE.md → Explore a design with the user), rendered
/// to build/prototypes/ apart from the real snapshots. Add a sheet here while exploring with the
/// user; once they pick, build the choice into WorldClockUI, then delete the sheet's file and
/// its entry (the next run removes its renders). Empty between explorations.
@MainActor let prototypes: [Snapshot] = []
