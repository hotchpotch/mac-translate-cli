// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "mac-translate-cli",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "trn", targets: ["trn"])
    ],
    targets: [
        .target(name: "TranslateCore"),
        .executableTarget(
            name: "trn",
            dependencies: ["TranslateCore"]
        ),
        .testTarget(
            name: "TranslateCoreTests",
            dependencies: ["TranslateCore"]
        )
    ]
)

