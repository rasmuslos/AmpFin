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
        .library(name: "AFApiKit", targets: ["AFApiKit"]),
        .library(name: "AFOfflineKit", targets: ["AFOfflineKit"]),
        .library(name: "AFPlaybackKit", targets: ["AFPlaybackKit"]),
    ],
    targets: [
        .target(name: "AFBaseKit"),
        .target(name: "AFApiKit", dependencies: [.byName(name: "AFBaseKit")]),
        .target(name: "AFOfflineKit", dependencies: [.byName(name: "AFBaseKit"), .byName(name: "AFApiKit")]),
        .target(name: "AFPlaybackKit", dependencies: [.byName(name: "AFBaseKit"), .byName(name: "AFApiKit")]),
    ]
)
