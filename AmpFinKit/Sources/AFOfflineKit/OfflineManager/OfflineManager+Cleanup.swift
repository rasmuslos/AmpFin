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
    func removeUnfinishedDownloads() async throws {
        let tracks = try await OfflineManager.shared.getUnfinishedDownloads()
        var albums = Set<OfflineAlbum>()
        
        tracks.forEach {
            albums.insert($0.album)
        }
        
        for album in albums {
            try await OfflineManager.shared.delete(album)
        }
    }
    
    @MainActor
    func deleteAllDownloads() async throws {
        // Delete all albums (should remove all tracks, too)
        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineAlbum>())
        for album in albums {
            try! delete(album)
        }
        
        // Ensure all tracks are deleted
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineTrack>())
        for track in tracks {
            delete(track)
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
                }
            }
        }
    }
}
