// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RKLoggingKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "RKLoggingKit",
            targets: ["RKLoggingKit"]
        )
    ],
    targets: [
        .target(
            name: "RKLoggingKit",
            dependencies: []
        ),
        .testTarget(
            name: "RKLoggingKitTests",
            dependencies: ["RKLoggingKit"]
        )
    ]
)
