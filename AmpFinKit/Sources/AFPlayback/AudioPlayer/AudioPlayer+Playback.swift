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

extension AudioPlayer: AudioEndpoint {
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
    
    public var allowQueueLater: Bool {
        endpoint?.allowQueueLater ?? false
    }
    
    public func seek(to seconds: Double) async {
        await endpoint?.seek(to: seconds)
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
    
    public func advance() {
        endpoint?.advance()
    }
    
    public func rewind() {
        endpoint?.rewind()
    }
    
    public func removePlayed(at index: Int) {
        endpoint?.removePlayed(at: index)
    }
    
    public func remove(at index: Int) -> Track? {
        endpoint?.remove(at: index)
    }
    
    public func queue(_ track: Track, after index: Int, updateUnalteredQueue: Bool = true, playbackInfo: PlaybackInfo) {
        var playbackInfo = playbackInfo
        playbackInfo.tracks = [track]
        
        if endpoint == nil || (endpoint?.nowPlaying == nil && endpoint?.queue.count == 0) {
            playbackInfo.queueLocation = .now
            startPlayback(tracks: [track], startIndex: 0, shuffle: false, playbackInfo: playbackInfo)
        } else {
            endpoint?.queue(track, after: index, updateUnalteredQueue: updateUnalteredQueue)
            #if !os(macOS)
            playbackInfo.donate()
            #endif
        }
    }
    public func queue(_ tracks: [Track], after index: Int, playbackInfo: PlaybackInfo) {
        var playbackInfo = playbackInfo
        playbackInfo.tracks = tracks
        
        if endpoint == nil || (endpoint?.nowPlaying == nil && endpoint?.queue.count == 0) {
            startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: playbackInfo)
        } else {
            endpoint?.queue(tracks, after: index)
            #if !os(macOS)
            playbackInfo.donate()
            #endif
        }
    }
    
    public func move(from index: Int, to destination: Int) {
        endpoint?.move(from: index, to: destination)
    }
    
    public func skip(to: Int) {
        endpoint?.skip(to: to)
    }
    
    public func restorePlayed(upTo index: Int) {
        endpoint?.restorePlayed(upTo: index)
    }
    
    internal func startPlayback(tracks: [AFFoundation.Track], startIndex: Int, shuffle: Bool) { exit(1) }
    internal func queue(_ track: AFFoundation.Track, after index: Int, updateUnalteredQueue: Bool) { exit(1) }
    internal func queue(_ tracks: [AFFoundation.Track], after index: Int) { exit(1) }
}
