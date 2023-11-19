//
//  DownloadManager+Cleanup.swift
//  Music
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation
import SwiftData

// MARK: Remove tracks

public extension OfflineManager {
    func removeUnfinishedDownloads() async throws {
        let tracks = try await OfflineManager.shared.getUnfinishedDownloads()
        var albums = Set<OfflineAlbum>()
        
        tracks.forEach {
            albums.insert($0.album)
        }
        
        for album in albums {
            try await OfflineManager.shared.deleteOfflineAlbum(album)
        }
    }
    
    @MainActor
    func deleteAllDownloads() async throws {
        // Delete all albums (should remove all tracks, too)
        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineAlbum>())
        for album in albums {
            try deleteOfflineAlbum(album)
        }
        
        // Ensure all tracks are deleted
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineTrack>())
        for track in tracks {
            delete(track)
        }
        
        try DownloadManager.shared.cleanupDirectory()
    }
}
