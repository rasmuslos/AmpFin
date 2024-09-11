//
//  File.swift
//
//
//  Created by Rasmus Krämer on 22.05.24.
//

import Foundation
import MediaPlayer
import AVKit
import AFFoundation
#if canImport(AppKit)
import AppKit
#endif

internal extension RemoteAudioEndpoint {
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
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nowPlaying.album.name
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
            #if !os(macOS)
            AudioPlayer.updateAudioSession(active: true)
            #endif
            
            active = true
        } else if nowPlaying == nil && active == true {
            #if !os(macOS)
            AudioPlayer.updateAudioSession(active: false)
            #endif
            queuePlayer.pause()
            
            nowPlayingInfo = [:]
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            active = false
        }
    }
    
    func updateNowPlayingCover() {
        let identifier = nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] as? String
        
        guard let nowPlaying = nowPlaying, identifier != nowPlaying.id else {
            return
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] = nowPlaying.id
        
        Task {
            guard let image = await nowPlaying.cover?.systemImage else {
                return
            }
            
            let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ in image })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}
