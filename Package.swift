// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "MASShortcut",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "MASShortcut",
                 targets: ["MASShortcut"])
    ],
    targets: [
        .target(
            name: "MASShortcut",
            path: "Sources/MASShortcut",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MASShortcutTests",
            dependencies: ["MASShortcut"],
            path: "Tests"
        )
    ],
    swiftLanguageModes: [.v6]
)
