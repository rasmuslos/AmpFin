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

@Observable
internal final class RemoteAudioEndpoint {
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
            
            if self?.lastTrackId != session.nowPlaying?.id {
                self?.lastTrackId = session.nowPlaying?.id
            }
        }
    }
}
