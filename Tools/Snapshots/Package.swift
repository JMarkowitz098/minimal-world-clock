// swift-tools-version:6.0
import PackageDescription

// Renders the shared SwiftUI views to PNGs so an AI agent (or a human) can check UI
// without launching the app. Later reused for App Store screenshots (M9).
// Run: swift run --package-path Tools/Snapshots Snapshots [name-filter]
let package = Package(
    name: "Snapshots",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../Packages/WorldClockKit")],
    targets: [
        .executableTarget(
            name: "Snapshots",
            dependencies: [
                .product(name: "WorldClockCore", package: "WorldClockKit"),
                .product(name: "WorldClockUI", package: "WorldClockKit"),
            ]
        ),
    ]
)
