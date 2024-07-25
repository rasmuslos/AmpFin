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

// MARK: Public (Helper)

public extension OfflineManager {
    func removeOrphans(context: ModelContext) throws {
        let albums = try offlineAlbums(context: context)
        let playlists = try offlinePlaylists(context: context)
        
        let albumTrackIds = reduceToChildrenIdentifiers(parents: albums)
        let playlistTrackIds = reduceToChildrenIdentifiers(parents: playlists)
        
        let tracks = try offlineTracks(context: context)
        let orphaned = tracks.filter { !albumTrackIds.contains($0.id) && !playlistTrackIds.contains($0.id) }
        
        for orphan in orphaned {
            delete(track: orphan, context: context)
        }
    }
}

// MARK: Public (Higher Order)

public extension OfflineManager {
    func delete() throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        for album in try offlineAlbums(context: context) {
            try delete(offlineAlbum: album, context: context)
        }
        
        for playlist in try offlinePlaylists(context: context) {
            try delete(playlist: playlist, context: context)
        }
        
        for track in try offlineTracks(context: context) {
            delete(track: track, context: context)
        }
        
        try DownloadManager.shared.cleanupDirectory()
    }
    
    func syncPlaysToJellyfinServer() {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        guard let plays = try? context.fetch(FetchDescriptor<OfflinePlay>()) else {
            return
        }
        
        Self.logger.info("Syncing \(plays.count) plays to the server")
        
        Task.detached {
            for play in plays {
                try await JellyfinClient.shared.playbackStopped(identifier: play.trackIdentifier, positionSeconds: play.position, playSessionId: nil)
                
                let context = ModelContext(PersistenceManager.shared.modelContainer)
                
                context.delete(play)
                try context.save()
            }
        }
    }
    
    func update() {
        let waitTime: Double = 60 * 60 * 12
        let lastUpdate = UserDefaults.standard.double(forKey: "lastOfflineItemUpdate")
        
        Task {
            try await syncLocalFavorites()
            
            await withThrowingTaskGroup(of: Void.self) {
                $0.addTask { try await self.updateTrackFavorites() }
                $0.addTask { try await self.updateAlbumFavorites() }
                $0.addTask { try await self.updatePlaylistFavorites() }
            }
        }
        
        if lastUpdate + waitTime < Date.timeIntervalSinceReferenceDate {
            UserDefaults.standard.set(Date.timeIntervalSinceReferenceDate, forKey: "lastOfflineItemUpdate")
            
            Task {
                for album in try offlineAlbums(context: ModelContext(PersistenceManager.shared.modelContainer)).map(Album.init) {
                    try await download(album: album)
                }
                
                for playlist in try playlists() {
                    try await download(playlist: playlist)
                }
                
                try? removeOrphans(context: ModelContext(PersistenceManager.shared.modelContainer))
            }
        }
    }
}
