//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import MediaPlayer
import SwiftUI
import AFFoundation
import AFNetwork

internal final class RemoteAudioEndpoint {
    let clientId: String
    let sessionId: String
    
    var nowPlaying: Track? {
        didSet {
            if oldValue != nowPlaying {
                NotificationCenter.default.post(name: AudioPlayer.trackDidChangeNotification, object: nil)
            }
        }
    }
    
    var _playing: Bool {
        didSet {
            if oldValue != _playing {
                NotificationCenter.default.post(name: AudioPlayer.playingDidChangeNotification, object: nil)
            }
        }
    }
    var canSeek: Bool
    var canSetVolume: Bool
    
    var _currentTime: Double
    var _volume: Float {
        didSet {
            if oldValue != _volume {
                NotificationCenter.default.post(name: AudioPlayer.volumeDidChangeNotification, object: nil)
            }
        }
    }
    
    var _shuffled: Bool
    var _repeatMode: RepeatMode
    
    var active: Bool
    var token: Any!
    
    var nowPlayingInfo = [String: Any]()
    var queuePlayer: AVQueuePlayer!
    
    init(session: Session) {
        active = false
        
        clientId = session.clientId
        sessionId = session.id
        
        nowPlaying = session.nowPlaying
        
        _playing = !session.isPaused
        _currentTime = session.position
        _volume = session.volumeLevel
        _shuffled = session.shuffled
        _repeatMode = .none
        
        canSeek = session.canSeek
        canSetVolume = session.canSetVolume
        
        setupObserver()
        
        #if !os(macOS)
        AudioPlayer.setupAudioSession()
        #endif
        
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

internal extension RemoteAudioEndpoint {
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
            
            NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
        }
    }
}
