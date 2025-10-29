// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VeloReadyCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "VeloReadyCore",
            targets: ["VeloReadyCore"]
        ),
        .executable(
            name: "VeloReadyCoreTests",
            targets: ["VeloReadyCoreTests"]
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
        .executableTarget(
            name: "VeloReadyCoreTests",
            dependencies: ["VeloReadyCore"],
            path: "Tests"
        ),
    ]
)
