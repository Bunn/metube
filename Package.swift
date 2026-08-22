// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MeTube",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MeTube", targets: ["MeTube"])
    ],
    targets: [
        .executableTarget(
            name: "MeTube",
            path: "Sources/MeTube"
        ),
        .testTarget(
            name: "MeTubeTests",
            dependencies: ["MeTube"],
            path: "Tests/MeTubeTests"
        )
    ]
)
