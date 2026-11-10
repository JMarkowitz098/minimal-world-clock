// swift-tools-version:6.0
import PackageDescription

// Shared code for every World Clock target (macOS app, desktop widget, iOS later).
// WorldClockCore: pure logic, Foundation only.
// WorldClockUI: cross-platform SwiftUI views + view models.
let package = Package(
    name: "WorldClockKit",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "WorldClockCore", targets: ["WorldClockCore"]),
        .library(name: "WorldClockUI", targets: ["WorldClockUI"]),
    ],
    targets: [
        .target(name: "WorldClockCore"),
        // No package resources: macOS App Store export doesn't re-sign SwiftPM resource
        // bundles (ITMS-90284). Shared images live in each app's asset catalog instead.
        .target(name: "WorldClockUI", dependencies: ["WorldClockCore"]),
        .testTarget(name: "WorldClockCoreTests", dependencies: ["WorldClockCore"]),
        .testTarget(name: "WorldClockUITests", dependencies: ["WorldClockUI"]),
    ]
)
