// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AmpFinKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "AFBaseKit", targets: ["AFBaseKit", "AFExtensionKit"]),
        .library(name: "AFOfflineKit", targets: ["AFOfflineKit"]),
        .library(name: "AFPlaybackKit", targets: ["AFPlaybackKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0")
    ],
    targets: [
        // Remove the underscore to disable app groups for sideloading
        .target(name: "AFBaseKit", dependencies: [.byName(name: "Starscream")], swiftSettings: [.define("_DISABLE_APP_GROUP")]),
        .target(name: "AFOfflineKit", dependencies: [.byName(name: "AFBaseKit")]),
        .target(
            name: "AFPlaybackKit",
            dependencies: [
                .byName(name: "AFBaseKit"),
                .byName(name: "AFExtensionKit"),
                .byName(name: "AFOfflineKit", condition: .when(platforms: [.iOS]))],
            resources: [.process("RemoteAudioEndpoint/silence.wav")]),
        .target(
            name: "AFExtensionKit",
            dependencies: [.byName(name: "AFBaseKit"), .byName(name: "AFOfflineKit", condition: .when(platforms: [.iOS]))]),
    ]
)
