//
//  DownloadManager+Cleanup.swift
//  Music
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation
import SwiftData
import AFFoundation
import AFNetwork

public extension OfflineManager {
    @MainActor
    func delete() throws {
        for album in try offlineAlbums() {
            try delete(offlineAlbum: album)
        }
        
        for playlist in try offlinePlaylists() {
            try delete(playlist: playlist)
        }
        
        for track in try offlineTracks() {
            delete(track: track)
        }
        
        try DownloadManager.shared.cleanupDirectory()
    }
    
    @MainActor
    func syncPlaysToJellyfinServer() {
        guard let plays = try? PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflinePlay>()) else {
            return
        }
        
        Self.logger.info("Syncing \(plays.count) plays to the server")
        
        Task.detached {
            for play in plays {
                try await JellyfinClient.shared.playbackStopped(identifier: play.trackIdentifier, positionSeconds: play.position)
                
                await MainActor.run {
                    PersistenceManager.shared.modelContainer.mainContext.delete(play)
                }
            }
        }
    }
    
    func update() {
        let waitTime: Double = 60 * 60 * 12
        let lastUpdate = UserDefaults.standard.double(forKey: "lastOfflineItemUpdate")
        
        if lastUpdate + waitTime > Date.timeIntervalSinceReferenceDate {
            updateFavorites()
        } else {
            UserDefaults.standard.set(Date.timeIntervalSinceReferenceDate, forKey: "lastOfflineItemUpdate")
            
            Task {
                for album in try await albums() {
                    try await download(album: album)
                }
                
                for playlist in try await playlists() {
                    try await download(playlist: playlist)
                }
                
                try? await removeOrphans()
            }
        }
    }
    
    @MainActor
    func removeOrphans() throws {
        let albums = try offlineAlbums()
        let playlists = try offlinePlaylists()
        
        let albumTrackIds = reduceToChildrenIdentifiers(parents: albums)
        let playlistTrackIds = reduceToChildrenIdentifiers(parents: playlists)
        
        let tracks = try offlineTracks()
        let orphaned = tracks.filter { !albumTrackIds.contains($0.id) && !playlistTrackIds.contains($0.id) }
        
        for orphan in orphaned {
            delete(track: orphan)
        }
    }
}
