// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ThreeThings",
    platforms: [.macOS(.v13), .iOS(.v16)],
    targets: [
        // The rules of the board (3 Things / Next / Done) and saving. No UI, so the iPhone app can share it.
        .target(name: "ThreeThingsCore", path: "Sources/ThreeThingsCore"),
        // The Mac app.
        .executableTarget(name: "ThreeThings", dependencies: ["ThreeThingsCore"], path: "Sources/ThreeThings"),
        .testTarget(name: "ThreeThingsCoreTests", dependencies: ["ThreeThingsCore"], path: "Tests/ThreeThingsCoreTests"),
    ]
)
