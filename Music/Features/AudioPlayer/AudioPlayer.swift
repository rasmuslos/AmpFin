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
        Task {
            stopPlayback()
            
            var tracks = tracks
            unalteredQueue = tracks
            
            shuffled = shuffle
            if shuffle {
                tracks.shuffle()
            }
            nowPlaying = tracks[startIndex]
            
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
        audioPlayer.removeAllItems()
        
        queue = []
        unalteredQueue = []
        
        playNextTrack()
        history = []
        
        notifyQueueChanged()
        updateAudioSession(active: false)
    }
    
    func playNextTrack() {
        audioPlayer.advanceToNextItem()
        
        trackDidFinish()
        notifyQueueChanged()
        NotificationCenter.default.post(name: NSNotification.TrackChange, object: nil)
    }
    func playPreviousTrack() {
        
        Task {
            if history.count < 1 {
                return
            }
            
            let previous = history.removeLast()
            let playerItem = await getAVPlayerItem(previous)
            audioPlayer.insert(playerItem, after: audioPlayer.currentItem)
            
            if let nowPlaying = nowPlaying {
                queue.insert(nowPlaying, at: 0)
                audioPlayer.insert(await getAVPlayerItem(nowPlaying), after: playerItem)
            }
            
            audioPlayer.advanceToNextItem()
            nowPlaying = previous
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
    
    func removeItem(index: Int) -> Track? {
        if queue.count < index + 1 {
            notifyQueueChanged()
            return nil
        }
        
        audioPlayer.remove(audioPlayer.items()[index + 1])
        let track = queue.remove(at: index)
        unalteredQueue.removeAll { $0.id == track.id }
        
        notifyQueueChanged()
        return track
    }
    func queueTrack(_ track: Track, index: Int, addToUnalteredQueue: Bool = true) {
        if queue.count == 0 {
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
        if let track = removeItem(index: from) {
            unalteredQueue.removeAll { $0.id == track.id }
            queueTrack(track, index: to)
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
            playNextTrack()
        }
    }
    func restoreHistory(index: Int) {
        for _ in index...history.count {
            if history.count > 0 {
                playPreviousTrack()
            }
        }
    }
    
    private func trackDidFinish() {
        if let nowPlaying = nowPlaying {
            Task.detached {
                try? await JellyfinClient.shared.reportPlaybackStopped(trackId: nowPlaying.id)
            }
            
            history.append(nowPlaying)
        }
        
        
        if queue.count > 0 {
            nowPlaying = queue.removeFirst()
            setupNowPlayingMetadata()
            
            Task.detached {
                try? await JellyfinClient.shared.reportPlaybackStarted(trackId: self.nowPlaying!.id)
            }
        } else {
            updateAudioSession(active: false)
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

// MARK: Reporting

extension AudioPlayer {
    private func setupTimeObserver() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            updateNowPlayingStatus()
            buffering = !(audioPlayer.currentItem?.isPlaybackLikelyToKeepUp ?? false)
            
            NotificationCenter.default.post(name: NSNotification.PositionUpdated, object: nil)
            
            let seconds = Int(currentTime())
            if seconds % 20 == 0, let nowPlaying = nowPlaying {
                Task.detached { [self] in
                    try? await JellyfinClient.shared.reportPlaybackProgress(trackId: nowPlaying.id, positionSeconds: currentTime(), paused: !isPlaying())
                }
            }
        }
    }
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleItemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc private func handleItemDidPlayToEndTime() {
        trackDidFinish()
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
            
            playNextTrack()
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            if history.count == 0 {
                return .commandFailed
            }
            
            playPreviousTrack()
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
    func setupNowPlayingMetadata() {
        if let nowPlaying = nowPlaying {
            Task.detached { [self] in
                nowPlayingInfo = [:]
                
                nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlaying.name
                nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlaying.artists.map { $0.name }.joined(separator: ", ")
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                
                if let cover = nowPlaying.cover, let data = try? Data(contentsOf: cover.url), let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in image })
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }
        }
    }
    func updateNowPlayingStatus() {
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
            print(DownloadManager.shared.getTrackUrl(trackId: track.id))
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
}

// MARK: Singleton

extension AudioPlayer {
    static let shared = AudioPlayer()
}
