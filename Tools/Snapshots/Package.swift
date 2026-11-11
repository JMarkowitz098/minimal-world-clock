// swift-tools-version:6.0
import PackageDescription

// Renders the shared SwiftUI views to PNGs so an AI agent (or a human) can check UI
// without launching the app, and the App Store screenshots (AppStore.swift).
// Run: swift run --package-path Tools/Snapshots Snapshots [name-filter | --app-store]
let package = Package(
    name: "Snapshots",
    platforms: [.macOS(.v15)],
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
