//
//  OfflineManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData

extension OfflineManager {
    @MainActor
    func downloadTrack(_ track: Track, album: OfflineAlbum) {
        if let existing = getOfflineTrackById(track.id) {
            if existing.isDownloaded() {
                return
            }
            
            deleteOfflineTrack(existing)
        }
        
        let downloadTask = DownloadManager.shared.downloadTrack(track: track)
        
        let offlineItem = OfflineTrack(
            id: track.id,
            name: track.name,
            sortName: track.sortName?.lowercased() ?? track.name.lowercased(),
            index: track.index,
            releaseDate: track.releaseDate,
            artists: track.artists,
            favorite: track.favorite,
            downloadId: downloadTask.taskIdentifier)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineItem)
        
        offlineItem.album = album
        downloadTask.resume()
    }
    
    @MainActor
    func getOfflineTrackById(_ id: String) -> OfflineTrack? {
        var track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.id == id })
        track.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(track).first
    }
    
    @MainActor
    func getOfflineTrackByDownloadId(_ taskId: Int) -> OfflineTrack? {
        var track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId == taskId })
        track.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(track).first
    }
    
    @MainActor
    func deleteOfflineTrack(_ track: OfflineTrack) {
        DownloadManager.shared.deleteTrack(trackId: track.id)
        PersistenceManager.shared.modelContainer.mainContext.delete(track)
        
        NotificationCenter.default.post(name: NSNotification.DownloadUpdated, object: track.id)
    }
    
    @MainActor
    func getUnfinishedDownloads() throws -> [OfflineTrack] {
        let track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId != nil })
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(track)
    }
}

// MARK: Getter

extension OfflineManager {
    @MainActor
    func getAllTracks() throws -> [Track] {
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineTrack>())
        return tracks.map(Track.convertFromOffline)
    }
    
    @MainActor func searchTracks(query: String) throws -> [Track] {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.sortName.contains(query) })
        descriptor.fetchLimit = 20
        
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        return tracks.map(Track.convertFromOffline)
    }
}
