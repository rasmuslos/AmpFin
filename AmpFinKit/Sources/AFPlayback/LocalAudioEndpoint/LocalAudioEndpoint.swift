//
//  AudioPlayer.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import Combine
import Network
import AVKit
import OSLog
import Defaults
import AFFoundation

@Observable
internal final class LocalAudioEndpoint: AudioEndpoint {
    let audioPlayer: AVQueuePlayer
    
    var history: [Track]
    var nowPlaying: Track?
    var queue: [Track]
    
    var avPlayerQueue: [String]
    var unalteredQueue: [Track]
    
    var nowPlayingInfo = [String: Any]()
    var playbackReporter: PlaybackReporter?
    
    // MARK: Helper
    
    var _playing: Bool = false
    var _currentTime: Double = 0
    
    var _shuffled: Bool = false
    var _repeatMode: RepeatMode = Defaults[.repeatMode]
    
    var buffering: Bool = false
    var duration: Double = 0
    
    /// Max bitrate in Kb/s
    var maxBitrate: Int?
    var outputRoute = LocalAudioEndpoint.audioRoute()
    var networkMonitor = NWPathMonitor();
    
    // MARK: Util
    
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "AudioPlayer")
    var volumeSubscription: AnyCancellable? = nil
    
    private init() {
        audioPlayer = .init()
        audioPlayer.actionAtItemEnd = Defaults[.repeatMode] == .track ? .pause : .advance
        audioPlayer.allowsExternalPlayback = false
        audioPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true
        
        history = []
        nowPlaying = nil
        queue = []
        
        avPlayerQueue = []
        unalteredQueue = []
        
        setupTimeObserver()
        setupObservers()
        setupNetworkPathMonitor()

        #if !os(macOS)
        AudioPlayer.updateAudioSession(active: false)
        #endif
    }
}

// MARK: Singleton

extension LocalAudioEndpoint {
    static let shared = LocalAudioEndpoint()
}
