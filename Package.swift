// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Rhythm",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "RhythmCore", targets: ["RhythmCore"]),
        .executable(name: "Rhythm", targets: ["Rhythm"]),
        .executable(name: "RhythmTDD", targets: ["RhythmTDD"])
    ],
    targets: [
        .target(
            name: "RhythmCore",
            path: "Sources/RhythmCore"
        ),
        .executableTarget(
            name: "Rhythm",
            dependencies: ["RhythmCore"],
            path: "Sources/RhythmApp"
        ),
        .executableTarget(
            name: "RhythmTDD",
            dependencies: ["RhythmCore"],
            path: "Sources/RhythmTDD"
        )
    ]
)
