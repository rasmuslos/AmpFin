//
//  AudioPlayer.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import Network
import Combine
import OSLog
import Defaults

import AVKit
import MediaPlayer

import AFFoundation
import AFNetwork

#if canImport(AFOffline)
import AFOffline
#endif

internal final class LocalAudioEndpoint: AudioEndpoint {
    let audioPlayer: AVQueuePlayer
    
    // MARK: Playback
    
    var playing: Bool {
        get {
            audioPlayer.rate > 0
        }
        set {
            guard newValue != playing else {
                return
            }
            
            if newValue {
                audioPlayer.play()
                
                #if !os(macOS)
                AudioPlayer.updateAudioSession(active: true)
                #endif
            } else {
                audioPlayer.pause()
            }
            
            updateNowPlayingWidget()
            updatePlaybackReporter(scheduled: false)
            
            NotificationCenter.default.post(name: AudioPlayer.playingDidChangeNotification, object: nil)
        }
    }
    var buffering: Bool {
        didSet {
            guard oldValue != buffering else {
                return
            }
            
            NotificationCenter.default.post(name: AudioPlayer.bufferingDidChangeNotification, object: nil)
        }
    }
    
    var currentTime: Double {
        get {
            audioPlayer.currentTime().seconds
        }
        set {
            Task {
                await seek(to: newValue)
            }
        }
    }
    var duration: Double {
        audioPlayer.currentItem?.duration.seconds ?? 0
    }
    
    var volume: Float {
        get {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            systemVolume
            #else
            audioPlayer.volume
            #endif
        }
        set {
            guard newValue != volume else {
                return
            }
            
            #if os(iOS) && !targetEnvironment(macCatalyst)
            Task { @MainActor in
                MPVolumeView.setVolume(newValue)
            }
            #else
            audioPlayer.volume = newValue
            #endif
            
            NotificationCenter.default.post(name: AudioPlayer.volumeDidChangeNotification, object: nil)
        }
    }
    
    var nowPlaying: Track? {
        didSet {
            guard oldValue != nowPlaying else {
                return
            }
            
            populateNowPlayingWidgetMetadata()
            
            if let nowPlaying = nowPlaying {
                playbackReporter = PlaybackReporter(trackId: nowPlaying.id, playSessionId: JellyfinClient.sessionID(itemId: nowPlaying.id, bitrate: maxBitrate), queue: queue)
                try? OfflineManager.shared.updateLastPlayed(trackId: nowPlaying.id)
            } else {
                playbackReporter = nil
            }
            
            NotificationCenter.default.post(name: AudioPlayer.trackDidChangeNotification, object: nil)
        }
    }
    
    // MARK: Queue
    
    var queue: [Track] {
        didSet {
            guard oldValue != queue else {
                return
            }
            
            populateAVPlayerQueue()
            checkAndUpdateInfiniteQueue()
            
            NotificationCenter.default.post(name: AudioPlayer.queueDidChangeNotification, object: nil)
        }
    }
    var infiniteQueue: [Track]? = [Track]() {
        didSet {
            guard oldValue != infiniteQueue else {
                return
            }
            
            NotificationCenter.default.post(name: AudioPlayer.queueDidChangeNotification, object: nil)
        }
    }
    
    var history: [Track] {
        didSet {
            guard oldValue != history else {
                return
            }
            
            NotificationCenter.default.post(name: AudioPlayer.queueDidChangeNotification, object: nil)
        }
    }
    
    var shuffled: Bool {
        didSet {
            guard oldValue != shuffled else {
                return
            }
            
            if(shuffled) {
                queue.shuffle()
            } else {
                queue = unalteredQueue.filter { track in
                    queue.contains { $0.id == track.id }
                }
            }
            
            NotificationCenter.default.post(name: AudioPlayer.queueModeDidChangeNotification, object: nil)
        }
    }
    var repeatMode: RepeatMode {
        didSet {
            guard oldValue != repeatMode else {
                return
            }
            
            Defaults[.repeatMode] = repeatMode
            audioPlayer.actionAtItemEnd = repeatMode == .track ? .pause : .advance
            
            if repeatMode != .infinite {
                infiniteQueue = []
            } else {
                checkAndUpdateInfiniteQueue()
            }
            
            NotificationCenter.default.post(name: AudioPlayer.queueModeDidChangeNotification, object: nil)
        }
    }
    
    var allowQueueLater: Bool {
        queue.count > 0
    }
    
    var avPlayerQueue: [String]
    var unalteredQueue: [Track]
    
    // MARK: Utility
    
    var systemVolume: Float
    var volumeSubscription: AnyCancellable?
    
    var rateSubscription: NSKeyValueObservation?
    
    var nowPlayingInfo: [String: Any]
    var playbackReporter: PlaybackReporter?
    
    /// Max bitrate in Kb/s
    var maxBitrate: Int? {
        didSet {
            guard oldValue != maxBitrate else {
                return
            }
            
            let currentTime = currentTime
            
            avPlayerQueue = []
            populateAVPlayerQueue()
            
            self.currentTime = currentTime
            
            if playbackReporter != nil, let nowPlaying {
                playbackReporter?.playSessionId = JellyfinClient.sessionID(itemId: nowPlaying.id, bitrate: maxBitrate)
            }
            
            NotificationCenter.default.post(name: AudioPlayer.bitrateDidChangeNotification, object: nil)
        }
    }
    var networkMonitor: NWPathMonitor
    var outputRoute: AudioPlayer.AudioRoute {
        let output = AVAudioSession.sharedInstance().currentRoute.outputs.first
        return .init(port: output?.portType ?? .builtInSpeaker, name: output?.portName ?? "-/-")
    }
    
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "AudioPlayer")
    
    private init() {
        audioPlayer = .init()
        audioPlayer.actionAtItemEnd = Defaults[.repeatMode] == .track ? .pause : .advance
        audioPlayer.allowsExternalPlayback = false
        audioPlayer.automaticallyWaitsToMinimizeStalling = false
        audioPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true
        
        nowPlaying = nil
        
        queue = []
        history = []
        
        shuffled = false
        repeatMode = Defaults[.repeatMode]
        
        avPlayerQueue = []
        unalteredQueue = []
        
        systemVolume = 0
        volumeSubscription = nil
        
        nowPlayingInfo = [:]
        networkMonitor = NWPathMonitor()
        
        buffering = false
        playing = false
        
        setupObservers()
        setupNetworkPathMonitor()
        
        #if !os(macOS)
        AudioPlayer.updateAudioSession(active: false)
        #endif
    }
}

internal extension LocalAudioEndpoint {
    static let shared = LocalAudioEndpoint()
}
