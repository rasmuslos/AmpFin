//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import MediaPlayer
import SwiftUI
import AFBase

@Observable
class RemoteAudioEndpoint {
    let clientId: String
    let sessionId: String
    
    var nowPlaying: Track?
    
    var _playing: Bool
    var canSeek: Bool
    var canSetVolume: Bool
    
    var _currentTime: Double
    var _volume: Float
    
    var _shuffled: Bool
    var _repeatMode: RepeatMode
    
    var active: Bool
    var token: Any!
    
    var nowPlayingInfo = [String: Any]()
    var queuePlayer: AVQueuePlayer!
    
    var lastTrackId: String?
    
    init(session: Session) {
        clientId = session.clientId
        sessionId = session.id
        active = false
        
        nowPlaying = session.nowPlaying
        _playing = !session.isPaused
        canSeek = session.canSeek
        canSetVolume = session.canSetVolume
        _currentTime = session.position
        _volume = session.volumeLevel
        _shuffled = session.shuffled
        _repeatMode = .none
        
        setupObserver()
        AudioPlayer.setupAudioSession()
        
        startDummyAudioPlayer()
        updateNowPlayingWidget()
    }
    
    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
        
        if let queuePlayer = queuePlayer {
            queuePlayer.pause()
            queuePlayer.removeAllItems()
        }
    }
}

extension RemoteAudioEndpoint {
    func setupObserver() {
        token = NotificationCenter.default.addObserver(forName: JellyfinWebSocket.sessionUpdateNotification, object: nil, queue: nil) { [weak self] notification in
            guard let session = notification.object as? Session else { return }
            
            self?.nowPlaying = session.nowPlaying
            self?._playing = !session.isPaused
            self?.canSeek = session.canSeek
            self?.canSetVolume = session.canSetVolume
            self?._currentTime = session.position
            self?._volume = session.volumeLevel
            self?._repeatMode = session.repeatMode
            self?._shuffled = session.shuffled
            
            self?.updateNowPlayingWidget()
            
            if self?.lastTrackId != session.nowPlaying?.id {
                self?.lastTrackId = session.nowPlaying?.id
            }
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
            if playing {
                queuePlayer.play()
            } else {
                queuePlayer.pause()
            }
            
            AudioPlayer.current.updateCommandCenter(favorite: nowPlaying.favorite)
            
            nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlaying.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlaying.artistName
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nowPlaying.album.albumName
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = nowPlaying.album.artistName
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = currentTime / duration
            
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused
            
            updateNowPlayingCover()
        }
        
        if nowPlaying != nil && active == false {
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
    var playing: Bool {
        get {
            _playing
        }
        set {
            Task {
                try? await JellyfinClient.shared.issuePlayStateCommand(sessionId: sessionId, command: _playing ? .pause : .play)
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
                try? await JellyfinClient.shared.setShuffleMode(sessionId: sessionId, shuffled: newValue)
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
                try? await JellyfinClient.shared.setRepeatMode(sessionId: sessionId, repeatMode: newValue)
            }
        }
    }
    
    public var volume: Float {
        get {
            _volume
        }
        set {
            Task {
                try? await JellyfinClient.shared.setOutputVolume(sessionId: sessionId, volume: newValue)
            }
        }
    }
    
    func seek(seconds: Double) async {
        try? await JellyfinClient.shared.seek(sessionId: sessionId, positionSeconds: seconds)
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
