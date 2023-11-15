//
//  AudioPlayer.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AVKit
import MediaPlayer
import OSLog

#if canImport(UIKit)
import UIKit
#endif

public class AudioPlayer {
    fileprivate let audioPlayer: AVQueuePlayer
    
    public fileprivate(set) var history: [Track]
    public fileprivate(set) var nowPlaying: Track?
    public fileprivate(set) var queue: [Track]
    
    fileprivate var unalteredQueue: [Track]
    
    public fileprivate(set) var shuffled: Bool = false
    public fileprivate(set) var repeatMode: RepeatMode = .none
    
    fileprivate var nowPlayingInfo = [String: Any]()
    fileprivate var playbackReporter: PlaybackReporter?
    
    public fileprivate(set) var buffering: Bool = false {
        didSet {
            Task { @MainActor in
                NotificationCenter.default.post(name: Self.playPause, object: nil)
            }
        }
    }
    
    let logger = Logger(subsystem: "io.rfk.music", category: "AudioPlayer")
    
    init() {
        audioPlayer = AVQueuePlayer()
        
        history = []
        nowPlaying = nil
        queue = []
        
        unalteredQueue = []
        
        setupRemoteControls()
        setupTimeObserver()
        setupObservers()
        
        updateAudioSession(active: false)
    }
}

// MARK: Methods

extension AudioPlayer {
    public func setPlaying(_ playing: Bool) {
        if playing {
            audioPlayer.play()
            updateAudioSession(active: true)
        } else {
            audioPlayer.pause()
        }
        
        updateNowPlayingStatus()
        playbackReporter?.update(positionSeconds: currentTime(), paused: !playing, scheduled: false)
        Task { @MainActor in
            NotificationCenter.default.post(name: Self.playPause, object: nil)
        }
    }
    public func isPlaying() -> Bool {
        audioPlayer.rate > 0
    }
    
    public func seek(seconds: Double) {
        audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
    }
    public func seek(seconds: Double) async {
        await audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
    }
    
    public func duration() -> Double {
        let duration = audioPlayer.currentItem?.duration.seconds ?? 0
        return duration.isFinite ? duration : 0
    }
    public func currentTime() -> Double {
        let currentTime = audioPlayer.currentTime().seconds
        return currentTime.isFinite ? currentTime : 0
    }
}

// MARK: Queue

extension AudioPlayer {
    public func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool) {
        if tracks.isEmpty {
            return
        }
        
        stopPlayback()
        
        var tracks = tracks
        unalteredQueue = tracks
        
        repeatMode = .none
        
        shuffled = shuffle
        if shuffle {
            tracks.shuffle()
        }
        setNowPlaying(track: tracks[startIndex])
        
        history = Array(tracks[0..<startIndex])
        queue = Array(tracks[startIndex + 1..<tracks.count])
        
        audioPlayer.insert(getAVPlayerItem(nowPlaying!), after: nil)
        populateQueue()
        
        notifyQueueChanged()
        
        setupAudioSession()
        updateAudioSession(active: true)
        setPlaying(true)
        setupNowPlayingMetadata()
        
        Task { @MainActor in
            NotificationCenter.default.post(name: Self.playbackStarted, object: nil)
        }
    }
    public func stopPlayback() {
        if isPlaying() {
            setPlaying(false)
        }
        
        audioPlayer.removeAllItems()
        
        queue = []
        unalteredQueue = []
        
        setNowPlaying(track: nil)
        history = []
        
        notifyQueueChanged()
        clearNowPlayingMetadata()
        updateAudioSession(active: false)
    }
    
    public func advanceToNextTrack() {
        if queue.count == 0 {
            restoreHistory(index: 0)
            if repeatMode != .queue {
                setPlaying(false)
            }
            
            return
        }
        
        audioPlayer.advanceToNextItem()
        
        trackDidFinish()
        notifyQueueChanged()
    }
    public func backToPreviousItem() {
        if currentTime() > 5 {
            seek(seconds: 0)
            return
        }
        if history.count < 1 {
            return
        }
        
        let previous = history.removeLast()
        let playerItem = getAVPlayerItem(previous)
        audioPlayer.insert(playerItem, after: audioPlayer.currentItem)
        
        if let nowPlaying = nowPlaying {
            queue.insert(nowPlaying, at: 0)
            audioPlayer.insert(getAVPlayerItem(nowPlaying), after: playerItem)
        }
        
        audioPlayer.advanceToNextItem()
        setNowPlaying(track: previous)
        setupNowPlayingMetadata()
        
        notifyQueueChanged()
    }
    
    public func shuffle(_ shuffle: Bool) {
        shuffled = shuffle
        
        if(shuffle) {
            queue.shuffle()
        } else {
            queue = unalteredQueue.filter { track in
                queue.contains { $0.id == track.id }
            }
        }
        
        audioPlayer.items().enumerated().forEach { index, item in
            if index != 0 {
                audioPlayer.remove(item)
            }
        }
        
        populateQueue()
        notifyQueueChanged()
    }
    
    public func setRepeatMode(_ repeatMode: RepeatMode) {
        self.repeatMode = repeatMode
        notifyQueueChanged()
    }
    
    public func removeHistoryTrack(index: Int) {
        history.remove(at: index)
        notifyQueueChanged()
    }
    
    public func removeTrack(index: Int) -> Track? {
        if queue.count < index + 1 {
            notifyQueueChanged()
            return nil
        }
        
        audioPlayer.remove(audioPlayer.items()[index + 1])
        let track = queue.remove(at: index)
        if let index = unalteredQueue.firstIndex(where: { $0.id == track.id }) {
            unalteredQueue.remove(at: index)
        }
        
        notifyQueueChanged()
        return track
    }
    public func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool = true) {
        if queue.count == 0 && nowPlaying == nil {
            startPlayback(tracks: [track], startIndex: 0, shuffle: false)
        } else {
            if updateUnalteredQueue {
                unalteredQueue.insert(track, at: index)
            }
            
            queue.insert(track, at: index)
            
            if audioPlayer.items().count > 0 {
                audioPlayer.insert(getAVPlayerItem(track), after: audioPlayer.items()[index])
            } else {
                audioPlayer.insert(getAVPlayerItem(track), after: nil)
            }
        }
        
        notifyQueueChanged()
    }
    public func queueTracks(_ tracks: [Track], index: Int) {
        if queue.count == 0 && nowPlaying == nil {
            startPlayback(tracks: tracks, startIndex: 0, shuffle: false)
        } else {
            for (i, track) in tracks.enumerated() {
                queueTrack(track, index: index + i)
            }
        }
    }
    
    public func moveTrack(from: Int, to: Int) {
        if let track = removeTrack(index: from) {
            if let index = unalteredQueue.firstIndex(where: { $0.id == track.id }) {
                unalteredQueue.remove(at: index)
            }
            
            if from < to {
                queueTrack(track, index: to - 1)
            } else {
                queueTrack(track, index: to)
            }
        }
        
        notifyQueueChanged()
    }
    
    public func skip(to: Int) {
        if queue.count < to + 1 {
            notifyQueueChanged()
            return
        }
        
        let id = queue[to].id
        while(nowPlaying?.id != id) {
            advanceToNextTrack()
        }
    }
    public func restoreHistory(index: Int) {
        let amount = history.count - index
        for track in history.suffix(amount).reversed() {
            queueTrack(track, index: 0, updateUnalteredQueue: false)
        }
        
        history.removeLast(amount)
        
        if let nowPlaying = nowPlaying {
            queueTrack(nowPlaying, index: queue.count)
        }
        
        advanceToNextTrack()
        history.removeLast()
    }
    
    private func trackDidFinish() {
        if let nowPlaying = nowPlaying {
            history.append(nowPlaying)
            // TODO: this
            // UserContext.donateTrack(nowPlaying, shuffle: shuffled, repeatMode: repeatMode)
        }
        
        if queue.count <= 0 {
            audioPlayer.removeAllItems()
            
            queue = history
            history = []
            
            populateQueue()
            setPlaying(repeatMode != .none)
        }
        
        setNowPlaying(track: queue.removeFirst())
        setupNowPlayingMetadata()
        
        notifyQueueChanged()
    }
    
    private func populateQueue() {
        for track in queue {
            audioPlayer.insert(getAVPlayerItem(track), after: nil)
        }
    }
}

// MARK: Observers

extension AudioPlayer {
    private func setupTimeObserver() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            updateNowPlayingStatus()
            buffering = !(audioPlayer.currentItem?.isPlaybackLikelyToKeepUp ?? false)
            
            playbackReporter?.update(positionSeconds: currentTime(), paused: !isPlaying(), scheduled: true)
            
            Task { @MainActor in
                NotificationCenter.default.post(name: Self.positionUpdated, object: nil)
            }
        }
    }
    private func setupObservers() {
        // The player is never discarded, so no removing of the observers is necessary
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: nil) { [weak self] _ in
            if self?.repeatMode == .track, let nowPlaying = self?.nowPlaying, let item = self?.getAVPlayerItem(nowPlaying) {
                // i tried really good things here, but only this stupid thing works
                self?.audioPlayer.removeAllItems()
                self?.audioPlayer.insert(item, after: nil)
                self?.populateQueue()
            } else {
                self?.trackDidFinish()
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance(), queue: nil) { [weak self] notification in
            guard let userInfo = notification.userInfo, let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            switch type {
            case .began:
                self?.setPlaying(false)
            case .ended:
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    self?.setPlaying(true)
                }
            default: ()
            }
        }
        
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            if let self = self {
                self.setNowPlaying(track: nil)
            }
        }
        #endif
    }
}

// MARK: Remote controls

extension AudioPlayer {
    private func setupRemoteControls() {
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
                audioPlayer.seek(to: CMTime(seconds: positionSeconds, preferredTimescale: 1000))
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            if queue.count == 0 {
                return .commandFailed
            }
            
            advanceToNextTrack()
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            if history.count == 0 {
                return .commandFailed
            }
            
            backToPreviousItem()
            return .success
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
        } catch {
            logger.fault("Failed to setup audio session")
        }
    }
    private func updateAudioSession(active: Bool) {
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

// MARK: Now Playing Widget

extension AudioPlayer {
    private func setupNowPlayingMetadata() {
        if let nowPlaying = nowPlaying {
            Task.detached { [self] in
                nowPlayingInfo = [:]
                
                nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlaying.name
                nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlaying.artists.map { $0.name }.joined(separator: ", ")
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nowPlaying.album.name
                nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = nowPlaying.album.artists.map { $0.name }.joined(separator: ", ")
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                
                setNowPlayingArtwork()
            }
        }
    }
    
    #if canImport(UIKit)
    private func setNowPlayingArtwork() {
        if let cover = nowPlaying?.cover, let data = try? Data(contentsOf: cover.url), let image = UIImage(data: data) {
            let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in image })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    #else
    private func setNowPlayingArtwork(image: UIImage) {
        // TODO: code this
    }
    #endif
    
    private func updateNowPlayingStatus() {
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration()
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime()
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = currentTime() / duration()
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = history.count
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = queue.count
        
        MPNowPlayingInfoCenter.default().playbackState = isPlaying() ? .playing : .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func clearNowPlayingMetadata() {
        nowPlayingInfo = [:]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: Helper

extension AudioPlayer {
    public func getTrackData() async -> (String, Int)? {
        let track = try? await audioPlayer.currentItem?.asset.load(.tracks).first
        let format = await track?.getMediaFormat()
        let bitrate = try? await track?.load(.estimatedDataRate)
        
        if var format = format, let bitrate = bitrate {
            while format.starts(with: ".") {
                format.removeFirst()
            }
            
            return (format, Int((bitrate / 1000).rounded()))
        }
        
        return nil
    }
    
    private func getAVPlayerItem(_ track: Track) -> AVPlayerItem {
        if track.offline == .downloaded {
            return AVPlayerItem(url: DownloadManager.shared.getTrackUrl(trackId: track.id))
        } else {
            #if os(watchOS)
            return AVPlayerItem(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "stream.aac").appending(queryItems: [
                URLQueryItem(name: "profile", value: "28"),
                URLQueryItem(name: "audioCodec", value: "aac"),
                URLQueryItem(name: "audioBitRate", value: "128000"),
                URLQueryItem(name: "audioSampleRate", value: "44100"),
            ]))
            #else
            return AVPlayerItem(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "stream").appending(queryItems: [
                URLQueryItem(name: "static", value: "true")
            ]))
            #endif
        }
    }
    private func notifyQueueChanged() {
        Task { @MainActor in
            NotificationCenter.default.post(name: AudioPlayer.queueUpdated, object: nil)
            NotificationCenter.default.post(name: AudioPlayer.trackChange, object: nil)
        }
    }
    
    private func setNowPlaying(track: Track?) {
        nowPlaying = track
        
        if let track = track {
            playbackReporter = PlaybackReporter(trackId: track.id)
        } else {
            playbackReporter = nil
        }
    }
    
    public enum RepeatMode: Int, Equatable {
        case none = 0
        case track = 1
        case queue = 2
    }
}

// MARK: Singleton

extension AudioPlayer {
    public static let shared = AudioPlayer()
}
