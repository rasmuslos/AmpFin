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
public class AudioPlayer {
    static let logger = Logger(subsystem: "io.rfk.ampfin", category: "AudioPlayer")
    
    var playbackInfo: PlaybackInfo?
    
    public private(set) var source: PlaybackSource = .none {
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
    
    private var endpoint: AudioEndpoint?
    private var remoteControlAvailable = false {
        didSet {
            Task.detached {
                try? await JellyfinClient.shared.setSessionCapabilities(allowRemoteControl: self.remoteControlAvailable)
            }
        }
    }
    
    init() {
        setupObservers()
        setupRemoteControls()
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
    
    public var volume: Float {
        endpoint?.volume ?? 0.5
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
    
    public func setVolume(_ volume: Float) {
        endpoint?.setVolume(volume)
    }
    
    public func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool, playbackInfo: PlaybackInfo) {
        self.playbackInfo = playbackInfo
        startPlayback(tracks: tracks, startIndex: startIndex, shuffle: shuffle)
    }
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool) {
        if source == .none {
            setupLocalPlayback()
        }
        
        endpoint?.startPlayback(tracks: tracks, startIndex: startIndex, shuffle: shuffle)
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
            startPlayback(tracks: [track], startIndex: 0, shuffle: false, playbackInfo: .init())
        } else {
            endpoint?.queueTrack(track, index: index, updateUnalteredQueue: updateUnalteredQueue)
        }
    }
    
    public func queueTracks(_ tracks: [Track], index: Int) {
        if endpoint == nil || (endpoint?.nowPlaying == nil && endpoint?.queue.count == 0) {
            startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: .init())
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

// MARK: Observers

extension AudioPlayer {
    func setupObservers() {
        NotificationCenter.default.addObserver(forName: JellyfinWebSocket.disconnectedNotification, object: nil, queue: nil) { [self] _ in
            if source == .jellyfinRemote {
                destroy()
            }
        }
        
        NotificationCenter.default.addObserver(forName: Item.affinityChanged, object: nil, queue: nil) { [self] event in
            updateCommandCenter(favorite: event.userInfo?["favorite"] as? Bool ?? false)
        }
        
        NotificationCenter.default.addObserver(forName: Self.trackChange, object: nil, queue: nil) { [self] _ in
            if let playbackInfo = playbackInfo, let nowPlaying = nowPlaying {
                Self.logger.info("Donating \(nowPlaying.name) to system")
                playbackInfo.donate(nowPlaying: nowPlaying, shuffled: shuffled, repeatMode: repeatMode, resumePlayback: true)
            }
        }
        
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
            let index = notification.userInfo?["index"] as? Int ?? 0
            
            Task.detached { [self] in
                guard let tracks = try? await trackIds?.parallelMap(JellyfinClient.shared.getTrack).filter({ $0 != nil }) as? [Track], !tracks.isEmpty else { return }
                
                if command == "playnow" {
                    startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init())
                } else if command == "playnext" {
                    queueTracks(tracks, index: 0)
                } else if command == "playlast" {
                    queueTracks(tracks, index: queue.count)
                }
            }
        }
    }
}

// MARK: Remote controls

extension AudioPlayer {
    func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [unowned self] event in
            setPlaying(true)
            return .success
        }
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            setPlaying(false)
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [unowned self] event in
            setPlaying(!isPlaying())
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent {
                let positionSeconds = changePlaybackPositionCommandEvent.positionTime
                endpoint?.seek(seconds: positionSeconds)
                
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            advanceToNextTrack()
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            backToPreviousItem()
            return .success
        }
        
        #if canImport(AFOffline)
        commandCenter.likeCommand.isEnabled = false
        commandCenter.likeCommand.addTarget { event in
            if let event = event as? MPFeedbackCommandEvent {
                Task.detached { [self] in
                    await nowPlaying?.setFavorite(favorite: !event.isNegative)
                }
                
                return .success
            }
            
            return .commandFailed
        }
        #endif
        
        commandCenter.changeShuffleModeCommand.isEnabled = true
        commandCenter.changeShuffleModeCommand.addTarget { event in
            if let event = event as? MPChangeShuffleModeCommandEvent {
                switch event.shuffleType {
                case .off:
                    self.shuffle(false)
                default:
                    self.shuffle(true)
                }
                
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.changeRepeatModeCommand.isEnabled = true
        commandCenter.changeRepeatModeCommand.addTarget { event in
            if let event = event as? MPChangeRepeatModeCommandEvent {
                switch event.repeatType {
                case .off:
                    self.setRepeatMode(.none)
                case .one:
                    self.setRepeatMode(.track)
                case .all:
                    self.setRepeatMode(.queue)
                @unknown default:
                    Self.logger.error("Unknown repeat type")
                }
                
                return .success
            }
            
            return .commandFailed
        }
    }
    
    func updateCommandCenter(favorite: Bool) {
        MPRemoteCommandCenter.shared().changeRepeatModeCommand.currentRepeatType = repeatMode == .track ? .one : repeatMode == .queue ? .all : .off
        MPRemoteCommandCenter.shared().likeCommand.isActive = favorite
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
