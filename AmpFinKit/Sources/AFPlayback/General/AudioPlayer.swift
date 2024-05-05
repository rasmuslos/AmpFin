//
//  Playback.swift
//  MusicKit
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBase
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
    internal var remoteControlAvailable = false {
        didSet {
            Task.detached {
                try? await JellyfinClient.shared.setSessionCapabilities(allowRemoteControl: self.remoteControlAvailable)
            }
        }
    }
    
    init() {
        DispatchQueue.main.async {
            self.setupObservers()
            self.setupRemoteControls()
        }
    }
}

// MARK: Endpoint util

extension AudioPlayer {
    func checkRemoteControlAvailability() {
        if source != .local {
            remoteControlAvailable = false
            return
        }
        
        remoteControlAvailable = allowRemoteControl
    }
    
    func setupLocalPlayback() {
        stopPlayback()
        
        source = .local
        endpoint = LocalAudioEndpoint.shared
    }
    
    public func destroy() {
        stopPlayback()
        JellyfinWebSocket.shared.stopReceivingSessionUpdates()
        
        endpoint = nil
        source = .none
    }
}

// MARK: Remote endpoint

public extension AudioPlayer {
    func startRemoteControl(session: Session) {
        Self.logger.info("Setting up remote endpoint \(session.name) (\(session.client))")
        
        destroy()
        
        JellyfinWebSocket.shared.requestSessionUpdates(clientId: session.clientId)
        source = .jellyfinRemote
        endpoint = RemoteAudioEndpoint(session: session)
    }
}

extension AudioPlayer {
    static func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            logger.fault("Failed to setup audio session")
        }
    }
    static func updateAudioSession(active: Bool) {
        #if os(watchOS)
        AVAudioSession.sharedInstance().activate { success, error in
            if error != nil {
                self.logger.fault("Failed to update audio session")
            }
        }
        #else
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        } catch {
            logger.fault("Failed to update audio session")
        }
        #endif
    }
}

// MARK: General methods

extension AudioPlayer {
    public var playing: Bool {
        get {
            endpoint?.playing ?? false
        }
        set {
            endpoint?.playing = newValue
        }
    }
    
    public var duration: Double {
        endpoint?.duration ?? 0
    }
    public var currentTime: Double {
        get {
            endpoint?.currentTime ?? 0
        }
        set {
            endpoint?.currentTime = newValue
        }
    }
    
    public var buffering: Bool {
        endpoint?.buffering ?? true
    }
    
    public var shuffled: Bool {
        get {
            endpoint?.shuffled ?? false
        }
        set {
            endpoint?.shuffled = newValue
        }
    }
    public var repeatMode: RepeatMode {
        get {
            endpoint?.repeatMode ?? .none
        }
        set {
            endpoint?.repeatMode = newValue
        }
    }
    
    public var volume: Float {
        get {
            endpoint?.volume ?? 0.5
        }
        set {
            endpoint?.volume = newValue
        }
    }
    
    public var history: [Track] {
        endpoint?.history ?? []
    }
    
    public var nowPlaying: Track? {
        endpoint?.nowPlaying
    }
    
    public var queue: [Track] {
        endpoint?.queue ?? []
    }
    
    public func seek(seconds: Double) async {
        await endpoint?.seek(seconds: seconds)
    }
    
    public func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool, playbackInfo: PlaybackInfo) {
        var playbackInfo = playbackInfo
        playbackInfo.tracks = Array(tracks[startIndex..<tracks.count])
        
        if source == .none {
            setupLocalPlayback()
        }
        
        endpoint?.startPlayback(tracks: tracks, startIndex: startIndex, shuffle: shuffle)
        
        playbackInfo.donate()
        self.playbackInfo = playbackInfo
    }
    
    public func stopPlayback() {
        playbackInfo = nil
        endpoint?.stopPlayback()
    }
    
    public func advanceToNextTrack() {
        endpoint?.advanceToNextTrack()
    }
    
    public func backToPreviousItem() {
        endpoint?.backToPreviousItem()
    }
    
    public func removeHistoryTrack(index: Int) {
        endpoint?.removeHistoryTrack(index: index)
    }
    
    public func removeTrack(index: Int) -> Track? {
        endpoint?.removeTrack(index: index)
    }
    
    public func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool = true, playbackInfo: PlaybackInfo) {
        var playbackInfo = playbackInfo
        playbackInfo.tracks = [track]
        
        if endpoint == nil || (endpoint?.nowPlaying == nil && endpoint?.queue.count == 0) {
            playbackInfo.queueLocation = .now
            startPlayback(tracks: [track], startIndex: 0, shuffle: false, playbackInfo: playbackInfo)
        } else {
            endpoint?.queueTrack(track, index: index, updateUnalteredQueue: updateUnalteredQueue)
            playbackInfo.donate()
        }
    }
    public func queueTracks(_ tracks: [Track], index: Int, playbackInfo: PlaybackInfo) {
        var playbackInfo = playbackInfo
        playbackInfo.tracks = tracks
        
        if endpoint == nil || (endpoint?.nowPlaying == nil && endpoint?.queue.count == 0) {
            startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: playbackInfo)
        } else {
            endpoint?.queueTracks(tracks, index: index)
            playbackInfo.donate()
        }
    }
    
    public func moveTrack(from: Int, to: Int) {
        endpoint?.moveTrack(from: from, to: to)
    }
    
    public func skip(to: Int) {
        endpoint?.skip(to: to)
    }
    
    public func restoreHistory(index: Int) {
        endpoint?.restoreHistory(index: index)
    }
    
    public func getTrackData() async -> Track.TrackData? {
        await endpoint?.getTrackData()
    }
}

// MARK: Helper

extension AudioPlayer {
    public enum PlaybackSource {
        case none
        case local
        case jellyfinRemote
    }
}

// MARK: Singleton

extension AudioPlayer {
    public static let current = AudioPlayer()
}
