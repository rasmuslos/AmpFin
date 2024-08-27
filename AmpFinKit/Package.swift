// swift-tools-version: 5.9

import PackageDescription

private let offlineCondition: TargetDependencyCondition? = .when(platforms: [.iOS, .watchOS, .visionOS, .macOS, .macCatalyst])

let package = Package(
    name: "AmpFinKit",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "AmpFinKit", targets: ["AmpFinKit"]),
        .library(name: "AFPlayback", targets: ["AFPlayback"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: .init(4, 0, 8)),
        .package(url: "https://github.com/sindresorhus/Defaults.git", from: .init(8, 2, 0)),
    ],
    targets: [
        // Umbrella library
        .target(name: "AmpFinKit", dependencies: [
            .targetItem(name: "AFFoundation", condition: .none),
            .targetItem(name: "AFExtension", condition: .none),
            .targetItem(name: "AFNetwork", condition: .none),
            
            .targetItem(name: "AFOffline", condition: offlineCondition),
        ]),
        
        // Foundation
        .target(name: "AFFoundation", dependencies: [
            .byName(name: "Defaults"),
            .byName(name: "Starscream"),
        ]),
        .target(name: "AFExtension", dependencies: [
            .targetItem(name: "AFFoundation", condition: .none),
            .targetItem(name: "AFNetwork", condition: .none),
            
            .targetItem(name: "AFOffline", condition: offlineCondition),
        ]),
        
        // Network
        .target(name: "AFNetwork", dependencies: [
            .targetItem(name: "AFFoundation", condition: .none),
        ]),
        
        // Offline
        .target(name: "AFOffline", dependencies: [
            .targetItem(name: "AFFoundation", condition: .none),
            .targetItem(name: "AFNetwork", condition: .none),
        ]),
        
        // Playback
        .target(name: "AFPlayback", dependencies: [
            .targetItem(name: "AFFoundation", condition: .none),
            .targetItem(name: "AFExtension", condition: .none),
            
            .targetItem(name: "AFOffline", condition: offlineCondition),
            
            .byName(name: "Defaults"),
        ], resources: [.process("RemoteAudioEndpoint/silence.wav")]),
    ]
)
