//
//  AudioPlayer.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AVKit
import OSLog
import AFFoundation
import MediaPlayer

@Observable
internal final class LocalAudioEndpoint: AudioEndpoint {
    let audioPlayer: AVPlayer
    
    var history: [Track]
    var nowPlaying: Track?
    var queue: [Track]
    
    var unalteredQueue: [Track]
    
    var nowPlayingInfo = [String: Any]()
    var playbackReporter: PlaybackReporter?
    
    // MARK: Helper
    
    var _playing: Bool = false
    var _currentTime: Double = 0
    
    var _shuffled: Bool = false
    var _repeatMode: RepeatMode = .none
    
    var buffering: Bool = false
    var duration: Double = 0
    
    // MARK: Util
    
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "AudioPlayer")
    
    private init() {
        audioPlayer = .init()
        audioPlayer.allowsExternalPlayback = false
        audioPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true
        
        history = []
        nowPlaying = nil
        queue = []
        
        unalteredQueue = []
        
        setupTimeObserver()
        setupObservers()
        
        #if !os(macOS)
        AudioPlayer.updateAudioSession(active: false)
        #endif
    }
}

// MARK: Singleton

extension LocalAudioEndpoint {
    static let shared = LocalAudioEndpoint()
}
