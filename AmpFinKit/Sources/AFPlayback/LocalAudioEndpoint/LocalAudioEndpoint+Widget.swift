//
//  File.swift
//
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import MediaPlayer
import AFFoundation
#if canImport(AFOffline)
import AFOffline
#endif
#if canImport(AppKit)
import AppKit
#endif

internal extension LocalAudioEndpoint {
    func populateNowPlayingWidgetMetadata() {
        if let nowPlaying {
            AudioPlayer.current.updateCommandCenter(favorite: nowPlaying.favorite)
            
            nowPlayingInfo = [:]
            
            nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlaying.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlaying.artistName
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nowPlaying.album.name
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = nowPlaying.album.artistName
            
            nowPlayingInfo[MPMediaItemPropertyPlayCount] = nowPlaying.playCount
            nowPlayingInfo[MPMediaItemPropertyReleaseDate] = nowPlaying.releaseDate
            
            nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] = nowPlaying.id
            
            nowPlayingInfo[MPMediaItemPropertyAlbumPersistentID] = nowPlaying.album.id
            nowPlayingInfo[MPMediaItemPropertyArtistPersistentID] = nowPlaying.artists.first?.id
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
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
    
    func updateNowPlayingWidget() {
        guard nowPlaying != nil else {
            return
        }
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = currentTime / duration
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = history.count + 1
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = history.count + 1 + queue.count
        
        MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func clearNowPlayingWidget() {
        nowPlayingInfo = [:]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
