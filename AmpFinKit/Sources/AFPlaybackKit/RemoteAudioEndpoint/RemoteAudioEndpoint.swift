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
    
    init(session: Session) {
        clientId = session.clientId
        sessionId = session.id
        
        nowPlaying = session.nowPlaying
        
        playing = !session.isPaused
        canSeek = session.canSeek
        canSetVolume = session.canSetVolume
        
        position = session.position
        volume = session.volumeLevel
        
        shuffled = false
        repeatMode = .none
        
        active = false
        
        setupObserver()
        AudioPlayer.setupAudioSession()
        
        update()
        
        NotificationCenter.default.post(name: AudioPlayer.playbackStarted, object: nil)
    }
    
    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
        
        NotificationCenter.default.post(name: AudioPlayer.trackChange, object: nil)
    }
}

extension RemoteAudioEndpoint {
    func setupObserver() {
        token = NotificationCenter.default.addObserver(forName: JellyfinWebSocket.sessionUpdateNotification, object: nil, queue: nil) { [weak self] notification in
            guard let object = notification.object as? String,
                  let data = object.data(using: .utf8, allowLossyConversion: false),
                  let jellyfinSession = try? JSONDecoder().decode(JellyfinClient.JellyfinSession.self, from: data) else { return }
            
            let session = Session.convertFromJellyfin(jellyfinSession)
            
            self?.nowPlaying = session.nowPlaying
            
            self?.playing = !session.isPaused
            self?.canSeek = session.canSeek
            self?.canSetVolume = session.canSetVolume
            
            self?.position = session.position
            self?.volume = session.volumeLevel
            
            self?.repeatMode = session.repeatMode
            
            self?.update()
            
            print(self?.nowPlaying)
            
            NotificationCenter.default.post(name: AudioPlayer.trackChange, object: nil)
            
            NotificationCenter.default.post(name: AudioPlayer.playPause, object: nil)
            NotificationCenter.default.post(name: AudioPlayer.positionUpdated, object: nil)
        }
    }
    
    func update() {
        if let nowPlaying = nowPlaying, active == false {
            NotificationCenter.default.post(name: AudioPlayer.playbackStarted, object: nil)
            
            AudioPlayer.updateAudioSession(active: true)
            AudioPlayer.current.updateCommandCenter(favorite: nowPlaying.favorite)
            
            var nowPlayingInfo = [String: Any]()
            
            nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlaying.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlaying.artistName
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nowPlaying.album.name
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = nowPlaying.album.artistName
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            active = true
        } else if nowPlaying == nil && active == true {
            AudioPlayer.updateAudioSession(active: false)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
            
            active = false
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
    
    // This does not work...
    
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
