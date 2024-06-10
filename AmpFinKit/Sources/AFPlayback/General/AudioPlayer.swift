//
//  Playback.swift
//  MusicKit
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFFoundation
import AFExtension
import MediaPlayer
import OSLog

#if canImport(AFOffline)
import AFOffline
#endif

@Observable
public final class AudioPlayer {
    static let logger = Logger(subsystem: "io.rfk.ampfin", category: "AudioPlayer")
    
    public var playbackInfo: PlaybackInfo?
    
    public internal(set) var source: PlaybackSource = .none {
        didSet {
            MPRemoteCommandCenter.shared().likeCommand.isEnabled = source == .local
            checkRemoteControlAvailability()
        }
    }
    public var allowRemoteControl = false {
        didSet {
            checkRemoteControlAvailability()
        }
    }
    
    internal var endpoint: AudioEndpoint?
    
    init() {
        Task {
            await self.setupObservers()
            await self.setupRemoteControls()
        }
    }
}

public extension AudioPlayer {
    enum PlaybackSource {
        case none
        case local
        case jellyfinRemote
    }
    
    struct AudioRoute {
        public let port: AVAudioSession.Port
        public let name: String
        
        public var showLabel: Bool {
            port == .bluetoothLE || port == .bluetoothHFP || port == .bluetoothA2DP || port == .carAudio || port == .airPlay
        }
    }
}

public extension AudioPlayer {
    static let current = AudioPlayer()
}
