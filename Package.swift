// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "FreeRDPClient",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "FreeRDPKit",
            path: "Sources/FreeRDPKit"
        ),
        .executableTarget(
            name: "FreeRDPClient",
            dependencies: ["FreeRDPKit"],
            path: "Sources/FreeRDPClient"
        ),
        .testTarget(
            name: "FreeRDPKitTests",
            dependencies: ["FreeRDPKit"],
            path: "Tests/FreeRDPKitTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
