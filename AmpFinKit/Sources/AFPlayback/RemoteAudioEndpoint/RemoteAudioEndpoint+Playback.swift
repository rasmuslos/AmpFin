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

extension RemoteAudioEndpoint: AudioEndpoint {
    var playing: Bool {
        get {
            _playing
        }
        set {
            Task {
                try? await JellyfinClient.shared.update(sessionId: sessionId, command: _playing ? .pause : .play)
            }
        }
    }
    
    var duration: Double {
        nowPlaying?.runtime ?? 0
    }
    var currentTime: Double {
        get {
            _currentTime
        }
        set {
            Task {
                await seek(seconds: newValue)
            }
        }
    }
    
    var shuffled: Bool {
        get {
            _shuffled
        }
        set {
            _shuffled = newValue
            
            Task {
                try? await JellyfinClient.shared.update(sessionId: sessionId, shuffled: newValue)
            }
        }
    }
    var repeatMode: RepeatMode {
        get {
            _repeatMode
        }
        set {
            _repeatMode = newValue
            
            Task {
                try? await JellyfinClient.shared.update(sessionId: sessionId, repeatMode: newValue)
            }
        }
    }
    
    public var volume: Float {
        get {
            _volume
        }
        set {
            Task {
                try? await JellyfinClient.shared.update(sessionId: sessionId, volume: newValue)
            }
        }
    }
    
    var mediaInfo: Track.MediaInfo? {
        get async {
            guard let itemId = nowPlaying?.id, let mediaInfo = try? await JellyfinClient.shared.mediaInfo(trackId: itemId) else {
                return nil
            }
            
            return mediaInfo
        }
    }
    
    func seek(seconds: Double) async {
        try? await JellyfinClient.shared.update(sessionId: sessionId, positionSeconds: seconds)
    }
    
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool) {
        Task {
            var tracks = tracks
            if shuffle {
                tracks = tracks.shuffled()
            }
            
            try? await JellyfinClient.shared.play(sessionId: sessionId, tracks: tracks, index: startIndex)
        }
    }
    
    func stopPlayback() {
        Task {
            try? await JellyfinClient.shared.update(sessionId: sessionId, command: .stop)
        }
    }
    
    func advanceToNextTrack() {
        Task {
            try? await JellyfinClient.shared.update(sessionId: sessionId, command: .next)
        }
    }
    
    func backToPreviousItem() {
        Task {
            try? await JellyfinClient.shared.update(sessionId: sessionId, command: .previous)
        }
    }
    
    func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool) {
        queueTracks([track], index: index)
    }
    
    func queueTracks(_ tracks: [Track], index: Int) {
        Task {
            try? await JellyfinClient.shared.queue(sessionId: sessionId, tracks: tracks, queuePosition: index == 0 ? .next : .last)
        }
    }
    
    // Jellyfin does not support these
    
    var queue: [Track] { [] }
    var history: [Track] { [] }
    var buffering: Bool { false }
    var outputPort: AVAudioSession.Port { .virtual }
    
    func skip(to: Int) {}
    func removeTrack(index: Int) -> Track? { nil }
    func removeHistoryTrack(index: Int) {}
    func moveTrack(from: Int, to: Int) {}
    func restoreHistory(index: Int) {}
}
