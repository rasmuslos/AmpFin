//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import MediaPlayer
import AFBaseKit

class RemoteAudioEndpoint {
    let clientId: String
    let sessionId: String
    
    var nowPlaying: Track?
    
    var playing: Bool
    var canSeek: Bool
    var canSetVolume: Bool
    
    var position: Double
    var volume: Float
    
    // these are not supported by the server (apparently)
    var shuffled: Bool
    var repeatMode: RepeatMode
    
    var active: Bool
    var token: Any!
    
    var nowPlayingInfo = [String: Any]()
    var queuePlayer: AVQueuePlayer!
    
    init(session: Session) {
        clientId = session.clientId
        sessionId = session.id
        active = false
        
        nowPlaying = session.nowPlaying
        playing = !session.isPaused
        canSeek = session.canSeek
        canSetVolume = session.canSetVolume
        position = session.position
        volume = session.volumeLevel
        shuffled = false
        repeatMode = .none
        
        setupObserver()
        AudioPlayer.setupAudioSession()
        
        startDummyAudioPlayer()
        updateNowPlayingWidget()
        
        NotificationCenter.default.post(name: AudioPlayer.playbackStarted, object: nil)
    }
    
    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
        
        if let queuePlayer = queuePlayer {
            queuePlayer.pause()
            queuePlayer.removeAllItems()
        }
        
        Task { @MainActor in
            NotificationCenter.default.post(name: AudioPlayer.trackChange, object: nil)
        }
    }
}

extension RemoteAudioEndpoint {
    func setupObserver() {
        token = NotificationCenter.default.addObserver(forName: JellyfinWebSocket.sessionUpdateNotification, object: nil, queue: nil) { [weak self] notification in
            guard let session = notification.object as? Session else { return }
            
            self?.nowPlaying = session.nowPlaying
            self?.playing = !session.isPaused
            self?.canSeek = session.canSeek
            self?.canSetVolume = session.canSetVolume
            self?.position = session.position
            self?.volume = session.volumeLevel
            self?.repeatMode = session.repeatMode
            
            self?.updateNowPlayingWidget()
            
            NotificationCenter.default.post(name: AudioPlayer.trackChange, object: nil)
            NotificationCenter.default.post(name: AudioPlayer.volumeChange, object: nil)
            
            NotificationCenter.default.post(name: AudioPlayer.playPause, object: nil)
            NotificationCenter.default.post(name: AudioPlayer.positionUpdated, object: nil)
        }
    }
    
    func startDummyAudioPlayer() {
        // this horrible abomination is required to show up in now playing
        let path = Bundle.module.path(forResource: "silence", ofType: "wav")
        let url = NSURL.fileURL(withPath: path!)
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        let _ = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
    }
    
    func updateNowPlayingWidget() {
        if let nowPlaying = nowPlaying {
            if isPlaying() {
                queuePlayer.play()
            } else {
                queuePlayer.pause()
            }
            
            AudioPlayer.current.updateCommandCenter(favorite: nowPlaying.favorite)
            
            nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlaying.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlaying.artistName
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nowPlaying.album.name
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = nowPlaying.album.artistName
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration()
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime()
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = currentTime() / duration()
            
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying() ? 1.0 : 0.0
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            MPNowPlayingInfoCenter.default().playbackState = isPlaying() ? .playing : .paused
            
            updateNowPlayingCover()
        }
        
        if nowPlaying != nil && active == false {
            NotificationCenter.default.post(name: AudioPlayer.playbackStarted, object: nil)
            AudioPlayer.updateAudioSession(active: true)
            
            active = true
        } else if nowPlaying == nil && active == true {
            AudioPlayer.updateAudioSession(active: false)
            queuePlayer.pause()
            
            nowPlayingInfo = [:]
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            active = false
        }
    }
    
    func updateNowPlayingCover() {
        let identifier = nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] as? String
        
        if let nowPlaying = nowPlaying, identifier != nowPlaying.id {
            nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] = nowPlaying.id
            
            #if canImport(UIKit)
            Task.detached { [self] in
                if let cover = nowPlaying.cover, let data = try? Data(contentsOf: cover.url), let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in image })
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                }
            }
            #else
            // TODO: code this
            #endif
        }
    }
}

extension RemoteAudioEndpoint: AudioEndpoint {
    func setPlaying(_ playing: Bool) {
        Task {
            try? await JellyfinClient.shared.issuePlayStateCommand(sessionId: sessionId, command: isPlaying() ? .pause : .play)
        }
    }
    
    func isPlaying() -> Bool {
        playing
    }
    
    func seek(seconds: Double) {
        Task {
            await seek(seconds: seconds)
        }
    }
    
    func seek(seconds: Double) async {
        try? await JellyfinClient.shared.seek(sessionId: sessionId, positionSeconds: seconds)
    }
    
    func duration() -> Double {
        nowPlaying?.runtime ?? 0
    }
    
    func currentTime() -> Double {
        position
    }
    
    func setVolume(_ volume: Float) {
        Task {
            try? await JellyfinClient.shared.setOutputVolume(sessionId: sessionId, volume: volume)
        }
    }
    
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool) {
        Task {
            var tracks = tracks
            if shuffle {
                tracks = tracks.shuffled()
            }
            
            try? await JellyfinClient.shared.playTracks(sessionId: sessionId, tracks: tracks, index: startIndex)
        }
    }
    
    func stopPlayback() {
        Task {
            try? await JellyfinClient.shared.issuePlayStateCommand(sessionId: sessionId, command: .stop)
        }
    }
    
    func advanceToNextTrack() {
        Task {
            try? await JellyfinClient.shared.issuePlayStateCommand(sessionId: sessionId, command: .next)
        }
    }
    
    func backToPreviousItem() {
        Task {
            try? await JellyfinClient.shared.issuePlayStateCommand(sessionId: sessionId, command: .previous)
        }
    }
    
    func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool) {
        queueTracks([track], index: index)
    }
    
    func queueTracks(_ tracks: [Track], index: Int) {
        Task {
            try? await JellyfinClient.shared.queueTracks(sessionId: sessionId, tracks: tracks, queuePosition: index == 0 ? .next : .last)
        }
    }
    
    func shuffle(_ shuffle: Bool) {
        shuffled = shuffle
        
        Task {
            try? await JellyfinClient.shared.setShuffleMode(sessionId: sessionId, shuffled: shuffle)
        }
    }
    
    func setRepeatMode(_ repeatMode: RepeatMode) {
        self.repeatMode = repeatMode
        
        Task {
            try? await JellyfinClient.shared.setRepeatMode(sessionId: sessionId, repeatMode: repeatMode)
        }
    }
    
    // Jellyfin does not support these
    
    var queue: [Track] { [] }
    var history: [Track] { [] }
    var buffering: Bool { false }
    
    func skip(to: Int) {}
    func removeTrack(index: Int) -> Track? { nil }
    func removeHistoryTrack(index: Int) {}
    func moveTrack(from: Int, to: Int) {}
    func restoreHistory(index: Int) {}
    func getTrackData() async -> (String, Int)? { nil }
}
