//
//  Playback.swift
//  MusicKit
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBaseKit

public class AudioPlayer {
    public private(set) var source: PlaybackSource = .none
    
    private var endpoint: AudioEndpoint?
    private var remoteControlAvailable = false
    
    init() {
        setupObservers()
    }
}

// MARK: Setup endpoints

extension AudioPlayer {
    public func setupRemoteControl() {
        Task.detached { [self] in
            try? await JellyfinClient.shared.setSessionCapabilities()
            remoteControlAvailable = true
        }
    }
    
    func setupLocalPlayback() {
        endpoint?.stopPlayback()
        
        source = .local
        endpoint = LocalAudioEndpoint.shared
    }
}

// MARK: General methods

extension AudioPlayer: AudioEndpoint {
    public var history: [Track] {
        endpoint?.history ?? []
    }
    
    public var nowPlaying: Track? {
        endpoint?.nowPlaying
    }
    
    public var queue: [Track] {
        endpoint?.queue ?? []
    }
    
    public var buffering: Bool {
        endpoint?.buffering ?? true
    }
    
    public var shuffled: Bool {
        endpoint?.shuffled ?? false
    }
    
    public var repeatMode: RepeatMode {
        endpoint?.repeatMode ?? .none
    }
    
    public func setPlaying(_ playing: Bool) {
        endpoint?.setPlaying(playing)
    }
    
    public func isPlaying() -> Bool {
        endpoint?.isPlaying() ?? false
    }
    
    public func seek(seconds: Double) {
        endpoint?.seek(seconds: seconds)
    }
    
    public func seek(seconds: Double) async {
        await endpoint?.seek(seconds: seconds)
    }
    
    public func duration() -> Double {
        endpoint?.duration() ?? 0
    }
    
    public func currentTime() -> Double {
        endpoint?.currentTime() ?? 0
    }
    
    public func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool) {
        if source == .none {
            setupLocalPlayback()
        }
        
        endpoint?.startPlayback(tracks: tracks, startIndex: startIndex, shuffle: shuffle)
    }
    
    public func stopPlayback() {
        endpoint?.stopPlayback()
        
        endpoint = nil
        source = .none
    }
    
    public func advanceToNextTrack() {
        endpoint?.advanceToNextTrack()
    }
    
    public func backToPreviousItem() {
        endpoint?.backToPreviousItem()
    }
    
    public func shuffle(_ shuffle: Bool) {
        endpoint?.shuffle(shuffle)
    }
    
    public func setRepeatMode(_ repeatMode: RepeatMode) {
        endpoint?.setRepeatMode(repeatMode)
    }
    
    public func removeHistoryTrack(index: Int) {
        endpoint?.removeHistoryTrack(index: index)
    }
    
    public func removeTrack(index: Int) -> Track? {
        endpoint?.removeTrack(index: index)
    }
    
    public func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool = true) {
        if endpoint == nil || (endpoint?.nowPlaying == nil && endpoint?.queue.count == 0) {
            startPlayback(tracks: [track], startIndex: 0, shuffle: false)
        } else {
            endpoint?.queueTrack(track, index: index, updateUnalteredQueue: updateUnalteredQueue)
        }
    }
    
    public func queueTracks(_ tracks: [Track], index: Int) {
        if endpoint == nil || (endpoint?.nowPlaying == nil && endpoint?.queue.count == 0) {
            startPlayback(tracks: tracks, startIndex: 0, shuffle: false)
        } else {
            endpoint?.queueTracks(tracks, index: index)
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
    
    public func getTrackData() async -> (String, Int)? {
        await endpoint?.getTrackData()
    }
}

// MARK: Receive remote events

extension AudioPlayer {
    func setupObservers() {
        // For some reason queue & repeat mode don't work
        // TODO: GeneralCommand/SetVolume
        
        NotificationCenter.default.addObserver(forName: JellyfinWebSocket.playStateCommandIssuedNotification, object: nil, queue: nil) { [self] notification in
            let command = notification.userInfo?["command"] as? String
            
            if command == "stop" {
                stopPlayback()
            } else if command == "playpause" {
                setPlaying(!isPlaying())
            } else if command == "previoustrack" {
                backToPreviousItem()
            } else if command == "nexttrack" {
                advanceToNextTrack()
            } else if command == "seek" {
                let position = notification.userInfo?["position"] as? UInt64 ?? 0
                seek(seconds: Double(position / 10_000_000))
            }
        }
        
        NotificationCenter.default.addObserver(forName: JellyfinWebSocket.playCommandIssuedNotification, object: nil, queue: nil) { [self] notification in
            let command = notification.userInfo?["command"] as? String
            let trackIds = notification.userInfo?["trackIds"] as? [String]
            
            Task.detached { [self] in
                guard let tracks = try? await trackIds?.parallelMap(JellyfinClient.shared.getTrack).filter({ $0 != nil }) as? [Track], !tracks.isEmpty else { return }
                
                if command == "playnow" {
                    startPlayback(tracks: tracks, startIndex: 0, shuffle: false)
                } else if command == "playnext" {
                    queueTracks(tracks, index: 0)
                } else if command == "playlast" {
                    queueTracks(tracks, index: queue.count)
                }
            }
        }
    }
}

// MARK: Helper

public extension AudioPlayer {
    enum PlaybackSource {
        case none
        case local
        case jellyfinRemote
    }
}

// MARK: Singleton

extension AudioPlayer {
    public static let current = AudioPlayer()
}
