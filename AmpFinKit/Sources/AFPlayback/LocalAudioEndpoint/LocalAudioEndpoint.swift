//
//  AudioPlayer.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AVKit
import OSLog
import AFBase

@Observable
internal class LocalAudioEndpoint: AudioEndpoint {
    let audioPlayer: AVQueuePlayer
    let audioSession: AVAudioSession
    
    var history: [Track]
    var nowPlaying: Track?
    var queue: [Track]
    
    var unalteredQueue: [Track]
    
    var nowPlayingInfo = [String: Any]()
    var playbackReporter: PlaybackReporter?
    
    // MARK: Computed
    
    var playing: Bool {
        get {
            _playing
        }
        set {
            _setPlaying(newValue)
        }
    }
    
    var duration: Double = 0
    var currentTime: Double {
        get {
            _currentTime
        }
        set {
            _seek(seconds: newValue)
        }
    }
    
    var buffering: Bool = false
    
    var shuffled: Bool {
        get {
            _shuffled
        }
        set {
            _shuffle(newValue)
        }
    }
    var repeatMode: RepeatMode {
        get {
            _repeatMode
        }
        set {
            _setRepeatMode(newValue)
        }
    }
    
    public var volume: Float {
        get {
            audioSession.outputVolume
        }
        set {
            _setVolume(newValue)
        }
    }
    
    // MARK: Helper
    
    var _playing: Bool = false
    var _currentTime: Double = 0
    
    var _shuffled: Bool = false
    var _repeatMode: RepeatMode = .none
    
    // MARK: Util
    
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "AudioPlayer")
    
    init() {
        audioPlayer = AVQueuePlayer()
        audioSession = AVAudioSession.sharedInstance()
        
        history = []
        nowPlaying = nil
        queue = []
        
        unalteredQueue = []
        
        setupTimeObserver()
        setupObservers()
        
        AudioPlayer.updateAudioSession(active: false)
    }
}

// MARK: Singleton

extension LocalAudioEndpoint {
    static let shared = LocalAudioEndpoint()
}
