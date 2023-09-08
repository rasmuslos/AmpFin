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
    
    fileprivate(set) var history: [SongItem]
    fileprivate(set) var nowPlaying: SongItem?
    fileprivate(set) var queue: [SongItem]
    
    fileprivate var unalteredQueue: [SongItem]
    
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
    func startPlayback(items: [SongItem], startIndex: Int, shuffle: Bool) {
        stopPlayback()
        
        var items = items
        unalteredQueue = items
        
        shuffled = shuffle
        if shuffle {
            items.shuffle()
        }
        nowPlaying = items[startIndex]
        
        history = Array(items[0..<startIndex])
        queue = Array(items[startIndex + 1..<items.count])
        
        audioPlayer.insert(getAVPlayerItem(nowPlaying!), after: nil)
        populateQueue()
        
        notifyQueueChanged()
        
        updateAudioSession(active: true)
        setupNowPlayingMetadata()
        setPlaying(true)
    }
    func stopPlayback() {
        audioPlayer.removeAllItems()
        
        queue = []
        unalteredQueue = []
        
        playNextItem()
        history = []
        
        notifyQueueChanged()
        updateAudioSession(active: false)
    }
    
    func playNextItem() {
        audioPlayer.advanceToNextItem()
        
        itemDidFinished()
        notifyQueueChanged()
        NotificationCenter.default.post(name: NSNotification.ItemChange, object: nil)
    }
    func playPreviousItem() {
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
        nowPlaying = previous
        setupNowPlayingMetadata()
        
        notifyQueueChanged()
    }
    
    func shuffle(_ shuffle: Bool) {
        shuffled = shuffle
        
        if(shuffle) {
            queue.shuffle()
        } else {
            queue = unalteredQueue.filter { item in
                queue.contains { $0.id == item.id }
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
    
    func removeItem(index: Int) -> SongItem? {
        if queue.count < index + 1 {
            notifyQueueChanged()
            return nil
        }
        
        audioPlayer.remove(audioPlayer.items()[index + 1])
        let item = queue.remove(at: index)
        
        notifyQueueChanged()
        return item
    }
    func addItem(_ item: SongItem, index: Int) {
        queue.insert(item, at: index)
        audioPlayer.insert(getAVPlayerItem(item), after: audioPlayer.items()[index])
        
        notifyQueueChanged()
    }
    
    func moveItem(from: Int, to: Int) {
        if let item = removeItem(index: from) {
            addItem(item, index: to)
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
            playNextItem()
        }
    }
    func restoreHistory(index: Int) {
        for _ in index...history.count {
            if history.count > 0 {
                playPreviousItem()
            }
        }
    }
    
    private func itemDidFinished() {
        if let nowPlaying = nowPlaying {
            Task.detached {
                try? await JellyfinClient.shared.reportPlaybackStopped(itemId: nowPlaying.id)
            }
            
            history.append(nowPlaying)
        }
        
        
        if queue.count > 0 {
            nowPlaying = queue.removeFirst()
            setupNowPlayingMetadata()
            
            Task.detached {
                try? await JellyfinClient.shared.reportPlaybackStarted(itemId: self.nowPlaying!.id)
            }
        } else {
            updateAudioSession(active: false)
        }
        
        notifyQueueChanged()
    }
    private func populateQueue() {
        queue.forEach {
            audioPlayer.insert(getAVPlayerItem($0), after: nil)
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
                    try? await JellyfinClient.shared.reportPlaybackProgress(itemId: nowPlaying.id, positionSeconds: currentTime(), paused: !isPlaying())
                }
            }
        }
    }
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleItemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc private func handleItemDidPlayToEndTime() {
        itemDidFinished()
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
            
            playNextItem()
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            if history.count == 0 {
                return .commandFailed
            }
            
            playPreviousItem()
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
    private func getAVPlayerItem(_ item: SongItem) -> AVPlayerItem {
        AVPlayerItem(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: item.id).appending(path: "stream").appending(queryItems: [
            URLQueryItem(name: "static", value: "true")
        ]))
    }
    private func notifyQueueChanged() {
        NotificationCenter.default.post(name: NSNotification.QueueUpdated, object: nil)
        NotificationCenter.default.post(name: NSNotification.ItemChange, object: nil)
    }
}

// MARK: Singleton

extension AudioPlayer {
    static let shared = AudioPlayer()
}
