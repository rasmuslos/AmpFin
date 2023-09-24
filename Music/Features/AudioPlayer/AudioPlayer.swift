//
//  AudioPlayer.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AVKit
import MediaPlayer

class AudioPlayer: NSObject {
    fileprivate let audioPlayer: AVQueuePlayer
    
    fileprivate(set) var history: [Track]
    fileprivate(set) var nowPlaying: Track?
    fileprivate(set) var queue: [Track]
    
    fileprivate var unalteredQueue: [Track]
    
    fileprivate(set) var shuffled: Bool = false
    fileprivate var buffering: Bool = false
    fileprivate var nowPlayingInfo = [String: Any]()
    
    fileprivate var playbackReporter: PlaybackReporter?
    
    override init() {
        audioPlayer = AVQueuePlayer()
        
        history = []
        nowPlaying = nil
        queue = []
        
        unalteredQueue = []
        
        super.init()
        
        setupRemoteControls()
        setupTimeObserver()
        setupObservers()
        
        setupAudioSession()
        updateAudioSession(active: false)
    }
}

// MARK: Methods

extension AudioPlayer {
    func setPlaying(_ playing: Bool) {
        if playing {
            audioPlayer.play()
        } else {
            audioPlayer.pause()
        }
        
        updateNowPlayingStatus()
        playbackReporter?.update(positionSeconds: currentTime(), paused: !playing, sheduled: false)
        NotificationCenter.default.post(name: NSNotification.PlayPause, object: nil)
    }
    public func isPlaying() -> Bool {
        audioPlayer.rate > 0
    }
    
    public func seek(seconds: Double) {
        audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
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

extension AudioPlayer {
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool) {
        if tracks.count == 0 {
            return
        }
        
        Task {
            stopPlayback()
            
            var tracks = tracks
            unalteredQueue = tracks
            
            shuffled = shuffle
            if shuffle {
                tracks.shuffle()
            }
            setNowPlaying(track: tracks[startIndex])
            
            history = Array(tracks[0..<startIndex])
            queue = Array(tracks[startIndex + 1..<tracks.count])
            
            audioPlayer.insert(await getAVPlayerItem(nowPlaying!), after: nil)
            populateQueue()
            
            notifyQueueChanged()
            
            updateAudioSession(active: true)
            setPlaying(true)
            setupNowPlayingMetadata()
        }
    }
    func stopPlayback() {
        if isPlaying() {
            playbackReporter?.ended(positionSeconds: currentTime())
            setPlaying(false)
        }
        
        audioPlayer.removeAllItems()
        
        queue = []
        unalteredQueue = []
        
        advanceToNextTrack()
        history = []
        
        notifyQueueChanged()
        updateAudioSession(active: false)
    }
    
    func advanceToNextTrack() {
        playbackReporter?.ended(positionSeconds: currentTime())
        audioPlayer.advanceToNextItem()
        
        trackDidFinish()
        notifyQueueChanged()
        NotificationCenter.default.post(name: NSNotification.TrackChange, object: nil)
    }
    func backToPreviousItem() {
        Task {
            if currentTime() > 5 {
                seek(seconds: 0)
                return
            }
            if history.count < 1 {
                return
            }
            
            playbackReporter?.ended(positionSeconds: currentTime())
            
            let previous = history.removeLast()
            let playerItem = await getAVPlayerItem(previous)
            audioPlayer.insert(playerItem, after: audioPlayer.currentItem)
            
            if let nowPlaying = nowPlaying {
                queue.insert(nowPlaying, at: 0)
                audioPlayer.insert(await getAVPlayerItem(nowPlaying), after: playerItem)
            }
            
            audioPlayer.advanceToNextItem()
            setNowPlaying(track: previous)
            setupNowPlayingMetadata()
            
            notifyQueueChanged()
        }
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
    func queueTrack(_ track: Track, index: Int, addToUnalteredQueue: Bool = true) {
        if queue.count == 0 && nowPlaying == nil {
            startPlayback(tracks: [track], startIndex: 0, shuffle: false)
        } else {
            Task {
                unalteredQueue.insert(track, at: index)
                queue.insert(track, at: index)
                audioPlayer.insert(await getAVPlayerItem(track), after: audioPlayer.items()[index])
            }
        }
        
        notifyQueueChanged()
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
        for _ in index...history.count {
            if history.count > 0 {
                advanceToNextTrack()
            }
        }
    }
    
    private func trackDidFinish() {
        if queue.count > 0 {
            if let nowPlaying = nowPlaying {
                history.append(nowPlaying)
            }
            
            setNowPlaying(track: queue.removeFirst())
            setupNowPlayingMetadata()
        } else {
            updateAudioSession(active: false)
            setPlaying(false)
            
            setNowPlaying(track: nil)
        }
        
        notifyQueueChanged()
    }
    private func populateQueue() {
        Task.detached { [self] in
            for track in queue {
                audioPlayer.insert(await getAVPlayerItem(track), after: nil)
            }
        }
    }
}

// MARK: Observers

extension AudioPlayer {
    private func setupTimeObserver() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            updateNowPlayingStatus()
            buffering = !(audioPlayer.currentItem?.isPlaybackLikelyToKeepUp ?? false)
            
            NotificationCenter.default.post(name: NSNotification.PositionUpdated, object: nil)
            playbackReporter?.update(positionSeconds: currentTime(), paused: !isPlaying(), sheduled: true)
            
            if currentTime() > duration() - 10 {
                playbackReporter?.ended(positionSeconds: duration())
            }
        }
    }
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleItemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [self] _ in
            playbackReporter?.ended(positionSeconds: currentTime())
        }
    }
    
    @objc private func handleItemDidPlayToEndTime() {
        trackDidFinish()
    }
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo, let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            setPlaying(false)
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                setPlaying(true)
            }
        default: ()
        }
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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            print(error, "failed to setup audio session")
        }
    }
    private func updateAudioSession(active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        } catch {
            print(error, "failed to update audio session")
        }
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
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                
                if let cover = nowPlaying.cover, cover.type == .local {
                    if let image = UIImage(contentsOfFile: cover.url.path()) {
                        setNowPlayingArtwork(image: image)
                    }
                } else {
                    if let cover = nowPlaying.cover, let data = try? Data(contentsOf: cover.url), let image = UIImage(data: data) {
                        setNowPlayingArtwork(image: image)
                    }
                }
            }
        }
    }
    private func setNowPlayingArtwork(image: UIImage) {
        let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in image })
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingStatus() {
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration()
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime()
        
        MPNowPlayingInfoCenter.default().playbackState = isPlaying() ? .playing : .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: Helper

extension AudioPlayer {
    private func getAVPlayerItem(_ track: Track) async -> AVPlayerItem {
        if await track.isDownloaded() {
            return AVPlayerItem(url: DownloadManager.shared.getTrackUrl(trackId: track.id))
        } else {
            return AVPlayerItem(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "stream").appending(queryItems: [
                URLQueryItem(name: "static", value: "true")
            ]))
        }
    }
    private func notifyQueueChanged() {
        NotificationCenter.default.post(name: NSNotification.QueueUpdated, object: nil)
        NotificationCenter.default.post(name: NSNotification.TrackChange, object: nil)
    }
    
    private func setNowPlaying(track: Track?) {
        nowPlaying = track
        
        if let track = track {
            playbackReporter = PlaybackReporter(trackId: track.id)
        }
    }
}

// MARK: Singleton

extension AudioPlayer {
    static let shared = AudioPlayer()
}
