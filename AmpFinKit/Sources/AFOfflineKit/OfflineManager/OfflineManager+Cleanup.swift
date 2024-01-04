//
//  DownloadManager+Cleanup.swift
//  Music
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation
import SwiftData
import AFBaseKit

// MARK: Remove tracks

public extension OfflineManager {
    @MainActor
    func deleteAll() async throws {
        for album in try getOfflineAlbums() {
            try delete(album: album)
        }
        
        for playlist in try getOfflinePlaylists() {
            try delete(playlist: playlist)
        }
        
        for track in try getOfflineTracks() {
            delete(track: track)
        }
        
        try DownloadManager.shared.cleanupDirectory()
    }
    
    func syncPlaysToJellyfinServer() {
        Task.detached { @MainActor in
            let plays = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflinePlay>())
            
            Self.logger.info("Syncing \(plays.count) plays to the server")
            
            for play in plays {
                do {
                    try await JellyfinClient.shared.reportPlaybackStopped(trackId: play.trackId, positionSeconds: play.positionSeconds)
                    PersistenceManager.shared.modelContainer.mainContext.delete(play)
                } catch {
                    Self.logger.fault("Error while syncing play to Jellyfin server \(play.trackId) (\(play.positionSeconds)")
                    break
                }
            }
        }
    }
    
    // this is not really efficient and an easy fix but ¯\_(ツ)_/¯
    @MainActor
    func removeOrphanedTracks() throws {
        let tracks = try getOfflineTracks()
        let orphaned = try tracks.filter { try !isTrackInUse(trackId: $0.id) }
        
        for orphan in orphaned {
            delete(track: orphan)
        }
    }
    
    func updateOfflineItems() {
        Task { @MainActor in
            for album in try getOfflineAlbums() {
                try await download(album: Album.convertFromOffline(album))
            }
            
            for playlist in try getOfflinePlaylists() {
                try await download(playlist: Playlist.convertFromOffline(playlist))
            }
            
            try removeOrphanedTracks()
        }
    }
}
