// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VeloReadyCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VeloReadyCore",
            targets: ["VeloReadyCore"]
        )
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "VeloReadyCore",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "VeloReadyCoreTests",
            dependencies: ["VeloReadyCore"],
            path: "Tests"
        ),
    ]
)
