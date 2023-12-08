// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MusicKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "MusicKit",
            targets: ["MusicKit"]),
    ],
    targets: [
        .target(name: "MusicKit",
                resources: [.process("Resources")])
    ]
)
