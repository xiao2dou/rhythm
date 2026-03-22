// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Rhythm",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Rhythm", targets: ["Rhythm"])
    ],
    targets: [
        .executableTarget(
            name: "Rhythm",
            path: "Sources/Rhythm"
        )
    ]
)
