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
import AFBaseKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AFOfflineKit)
import AFOfflineKit
#endif

class LocalAudioEndpoint: AudioEndpoint {
    fileprivate let audioPlayer: AVQueuePlayer
    fileprivate var audioSession: AVAudioSession
    
    fileprivate(set) var history: [Track]
    fileprivate(set) var nowPlaying: Track?
    fileprivate(set) var queue: [Track]
    
    fileprivate var unalteredQueue: [Track]
    
    fileprivate(set) var shuffled: Bool = false
    fileprivate(set) var repeatMode: RepeatMode = .none
    
    fileprivate var nowPlayingInfo = [String: Any]()
    fileprivate var playbackReporter: PlaybackReporter?
    
    fileprivate(set) var buffering: Bool = false {
        didSet {
            Task { @MainActor in
                NotificationCenter.default.post(name: AudioPlayer.playPause, object: nil)
            }
        }
    }
    
    let logger = Logger(subsystem: "io.rfk.music", category: "AudioPlayer")
    
    init() {
        audioPlayer = AVQueuePlayer()
        audioSession = AVAudioSession.sharedInstance()
        
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

extension LocalAudioEndpoint {
    func setPlaying(_ playing: Bool) {
        if playing {
            audioPlayer.play()
            updateAudioSession(active: true)
        } else {
            audioPlayer.pause()
        }
        
        updateNowPlayingStatus()
        updatePlaybackReporter(scheduled: false)
        Task { @MainActor in
            NotificationCenter.default.post(name: AudioPlayer.playPause, object: nil)
        }
    }
    func isPlaying() -> Bool {
        audioPlayer.rate > 0
    }
    
    func seek(seconds: Double) {
        audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000)) { _ in
            self.updatePlaybackReporter(scheduled: false)
        }
    }
    func seek(seconds: Double) async {
        await audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
        updatePlaybackReporter(scheduled: false)
    }
    
    func duration() -> Double {
        let duration = audioPlayer.currentItem?.duration.seconds ?? 0
        return duration.isFinite ? duration : 0
    }
    func currentTime() -> Double {
        let currentTime = audioPlayer.currentTime().seconds
        return currentTime.isFinite ? currentTime : 0
    }
}

// MARK: Queue

extension LocalAudioEndpoint {
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool) {
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
        
        history = Array(tracks[0..<startIndex])
        queue = Array(tracks[startIndex + 1..<tracks.count])
        
        setNowPlaying(track: tracks[startIndex])
        
        audioPlayer.insert(getAVPlayerItem(nowPlaying!), after: nil)
        populateQueue()
        
        notifyQueueChanged()
        
        setupAudioSession()
        updateAudioSession(active: true)
        setPlaying(true)
        setupNowPlayingMetadata()
        
        Task { @MainActor in
            NotificationCenter.default.post(name: AudioPlayer.playbackStarted, object: nil)
        }
    }
    func stopPlayback() {
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
    
    func advanceToNextTrack() {
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
    func backToPreviousItem() {
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
    
    func shuffle(_ shuffle: Bool) {
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
    
    func setRepeatMode(_ repeatMode: RepeatMode) {
        self.repeatMode = repeatMode
        notifyQueueChanged()
    }
    
    func removeHistoryTrack(index: Int) {
        history.remove(at: index)
        notifyQueueChanged()
    }
    
    func removeTrack(index: Int) -> Track? {
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
    func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool = true) {
        if updateUnalteredQueue {
            unalteredQueue.insert(track, at: index)
        }
        
        queue.insert(track, at: index)
        
        if audioPlayer.items().count > 0 {
            audioPlayer.insert(getAVPlayerItem(track), after: audioPlayer.items()[index])
        } else {
            audioPlayer.insert(getAVPlayerItem(track), after: nil)
        }
        
        notifyQueueChanged()
    }
    func queueTracks(_ tracks: [Track], index: Int) {
        for (i, track) in tracks.enumerated() {
            queueTrack(track, index: index + i)
        }
    }
    
    func moveTrack(from: Int, to: Int) {
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
    
    func skip(to: Int) {
        if queue.count < to + 1 {
            notifyQueueChanged()
            return
        }
        
        let id = queue[to].id
        while(nowPlaying?.id != id) {
            advanceToNextTrack()
        }
    }
    func restoreHistory(index: Int) {
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

extension LocalAudioEndpoint {
    private func setupTimeObserver() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            updateNowPlayingStatus()
            buffering = !(audioPlayer.currentItem?.isPlaybackLikelyToKeepUp ?? false)
            
            updatePlaybackReporter(scheduled: true)
            
            Task { @MainActor in
                NotificationCenter.default.post(name: AudioPlayer.positionUpdated, object: nil)
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
        
        NotificationCenter.default.addObserver(forName: Item.affinityChanged, object: nil, queue: nil) { [weak self] event in
            print(event.userInfo?["favorite"] as? Bool ?? false)
            
            self?.updateCommandCenter(favorite: event.userInfo?["favorite"] as? Bool ?? false)
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

extension LocalAudioEndpoint {
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
            advanceToNextTrack()
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            backToPreviousItem()
            return .success
        }
        
        #if canImport(AFOfflineKit)
        commandCenter.likeCommand.isEnabled = true
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
                    self.logger.error("Unknown repeat type")
                }
                
                return .success
            }
            
            return .commandFailed
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
        } catch {
            logger.fault("Failed to setup audio session")
        }
    }
    private func updateAudioSession(active: Bool) {
        #if os(watchOS)
        audioSession.activate { success, error in
            if error != nil {
                self.logger.fault("Failed to update audio session")
            }
        }
        #else
        do {
            try audioSession.setActive(active)
        } catch {
            logger.fault("Failed to update audio session")
        }
        #endif
    }
    
    func updateCommandCenter(favorite: Bool) {
        MPRemoteCommandCenter.shared().changeRepeatModeCommand.currentRepeatType = repeatMode == .track ? .one : repeatMode == .queue ? .all : .off
        MPRemoteCommandCenter.shared().likeCommand.isActive = favorite
    }
}

// MARK: Now Playing Widget

extension LocalAudioEndpoint {
    private func setupNowPlayingMetadata() {
        if let nowPlaying = nowPlaying {
            Task.detached { [self] in
                nowPlayingInfo = [:]
                
                nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlaying.name
                nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlaying.artistName
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nowPlaying.album.name
                nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = nowPlaying.album.artistName
                
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

extension LocalAudioEndpoint {
    func getTrackData() async -> (String, Int)? {
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
    
    func getAVPlayerItem(_ track: Track) -> AVPlayerItem {
        #if canImport(AFOfflineKit)
        if DownloadManager.shared.isTrackDownloaded(trackId: track.id) {
            return AVPlayerItem(url: DownloadManager.shared.getTrackUrl(trackId: track.id))
        }
        #endif
        
        #if os(watchOS)
        return AVPlayerItem(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "stream").appending(queryItems: [
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
    
    func notifyQueueChanged() {
        Task { @MainActor in
            NotificationCenter.default.post(name: AudioPlayer.queueUpdated, object: nil)
            NotificationCenter.default.post(name: AudioPlayer.trackChange, object: nil)
        }
    }
    
    func updatePlaybackReporter(scheduled: Bool) {
        playbackReporter?.update(
            positionSeconds: currentTime(),
            paused: !self.isPlaying(),
            repeatMode: repeatMode,
            shuffled: shuffled,
            volume: audioSession.outputVolume,
            scheduled: scheduled)
    }
    
    func setNowPlaying(track: Track?) {
        nowPlaying = track
        
        if let track = track {
            updateCommandCenter(favorite: track.favorite)
        }
        
        if let track = track {
            playbackReporter = PlaybackReporter(trackId: track.id, queue: queue)
        } else {
            playbackReporter = nil
        }
    }
}

// MARK: Singleton

extension LocalAudioEndpoint {
    static let shared = LocalAudioEndpoint()
}
