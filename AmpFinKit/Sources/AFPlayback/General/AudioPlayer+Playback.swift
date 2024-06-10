//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 22.05.24.
//

import Foundation
import AVKit
import AFFoundation
import AFNetwork

internal extension AudioPlayer {
    func checkRemoteControlAvailability() {
        var remoteControlAvailable = true
        
        if source != .local {
            remoteControlAvailable = false
            return
        }
        
        Task { [remoteControlAvailable] in
            try? await JellyfinClient.shared.update(allowRemoteControl: remoteControlAvailable)
        }
    }
    
    func setupLocalPlayback() {
        stopPlayback()
        
        source = .local
        endpoint = LocalAudioEndpoint.shared
    }
}

public extension AudioPlayer {
    func startRemoteControl(session: Session) {
        Self.logger.info("Setting up remote endpoint \(session.name) (\(session.client))")
        
        stopPlayback()
        
        JellyfinWebSocket.shared.beginObservingSessionUpdated(clientId: session.clientId)
        source = .jellyfinRemote
        endpoint = RemoteAudioEndpoint(session: session)
    }
}

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
        guard let duration = endpoint?.duration, duration.isFinite, !duration.isNaN else {
            return 0
        }
        
        return duration
    }
    public var currentTime: Double {
        get {
            guard let currentTime = endpoint?.currentTime, currentTime.isFinite, !currentTime.isNaN else {
                return 0
            }
            
            guard currentTime <= duration else {
                return duration
            }
            
            return currentTime
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
            endpoint?.volume ?? 0
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
    
    public var mediaInfo: Track.MediaInfo? {
        get async {
            await endpoint?.mediaInfo
        }
    }
    
    public var outputRoute: AudioRoute {
        endpoint?.outputRoute ?? .init(port: .builtInSpeaker, name: "-/-")
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
        
        #if !os(macOS)
        playbackInfo.donate()
        #endif
        self.playbackInfo = playbackInfo
    }
    
    public func stopPlayback() {
        playbackInfo = nil
        endpoint?.stopPlayback()
        
        JellyfinWebSocket.shared.stopObservingSessionUpdated()
        
        endpoint = nil
        source = .none
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
            #if !os(macOS)
            playbackInfo.donate()
            #endif
        }
    }
    public func queueTracks(_ tracks: [Track], index: Int, playbackInfo: PlaybackInfo) {
        var playbackInfo = playbackInfo
        playbackInfo.tracks = tracks
        
        if endpoint == nil || (endpoint?.nowPlaying == nil && endpoint?.queue.count == 0) {
            startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: playbackInfo)
        } else {
            endpoint?.queueTracks(tracks, index: index)
            #if !os(macOS)
            playbackInfo.donate()
            #endif
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
}
