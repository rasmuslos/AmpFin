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
    func setupNowPlayingMetadata() {
        if let nowPlaying = nowPlaying {
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
            setRemoteNowPlayingProperties()
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
    
    func setRemoteNowPlayingProperties() {
        guard let nowPlaying = nowPlaying else {
            return
        }
        
        Task {
            guard let cover = nowPlaying.cover, let data = try? Data(contentsOf: cover.url) else {
                return
            }
            
            #if canImport(UIKit)
            let image = UIImage(data: data)
            #elseif canImport(AppKit)
            let image = NSImage(data: data)
            #endif
            
            guard let image = image else {
                return
            }
            
            let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ in image })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
        Task {
            let lyrics: Track.Lyrics?
            
            #if canImport(AFOffline)
            lyrics = try? await OfflineManager.shared.lyrics(trackId: nowPlaying.id)
            #else
            lyrics = try? await JellyfinClient.shared.lyrics(trackId: nowPlaying.id)
            #endif
            
            guard let lyrics = lyrics else {
                return
            }
            
            nowPlayingInfo[MPMediaItemPropertyLyrics] = lyrics.map { "\($0): \($1 ?? "")" }.joined(separator: "\n")
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}
