// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AmpFinKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "AFBaseKit", targets: ["AFBaseKit"]),
        .library(name: "AFOfflineKit", targets: ["AFOfflineKit"]),
        .library(name: "AFPlaybackKit", targets: ["AFPlaybackKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0")
    ],
    targets: [
        .target(name: "AFBaseKit", dependencies: [.byName(name: "Starscream")]),
        .target(name: "AFOfflineKit", dependencies: [.byName(name: "AFBaseKit")]),
        .target(name: "AFPlaybackKit", dependencies: [.byName(name: "AFBaseKit")]),
    ]
)
