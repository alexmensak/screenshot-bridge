// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ScreenshotBridge",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "ScreenshotBridge", targets: ["ScreenshotBridge"])],
    targets: [
        .target(name: "BridgeCore"),
        .executableTarget(name: "ScreenshotBridge", dependencies: ["BridgeCore"],
            swiftSettings: [.defaultIsolation(MainActor.self), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]),
        .testTarget(name: "BridgeCoreTests", dependencies: ["BridgeCore"])
    ]
)
