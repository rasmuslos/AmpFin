//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import MediaPlayer

internal extension LocalAudioEndpoint {
    func setupNowPlayingMetadata() {
        if let nowPlaying = nowPlaying {
            Task.detached { [self] in
                nowPlayingInfo = [:]
                
                nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlaying.name
                nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlaying.artistName
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nowPlaying.album.name
                nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = nowPlaying.album.artistName
                
                nowPlayingInfo[MPMediaItemPropertyPersistentID] = nowPlaying.id
                // nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] = nowPlaying.id
                
                nowPlayingInfo[MPMediaItemPropertyAlbumPersistentID] = nowPlaying.album.id
                nowPlayingInfo[MPMediaItemPropertyArtistPersistentID] = nowPlaying.artists.first?.id
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                
                setNowPlayingArtwork()
            }
        }
    }
    
    func updateNowPlayingStatus() {
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = currentTime / duration
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = history.count + 1
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = history.count + 1 + queue.count
        
        MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func clearNowPlayingMetadata() {
        nowPlayingInfo = [:]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    #if canImport(UIKit)
    func setNowPlayingArtwork() {
        if let cover = nowPlaying?.cover, let data = try? Data(contentsOf: cover.url), let image = UIImage(data: data) {
            let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in image })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    #else
    func setNowPlayingArtwork() {
        // TODO: code this
    }
    #endif
}
