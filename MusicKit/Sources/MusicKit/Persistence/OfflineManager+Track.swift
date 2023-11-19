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
    func download(_ track: Track, album: OfflineAlbum) {
        if let existing = getOfflineTrack(trackId: track.id) {
            if existing.downloadId == nil {
                return
            }
            
            delete(existing)
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
        
        Task.detached {
            if let lyrics = try? await JellyfinClient.shared.getLyrics(trackId: track.id) {
                Task.detached { @MainActor in
                    let offlineLyrics = OfflineLyrics(trackId: track.id, lyrics: lyrics)
                    PersistenceManager.shared.modelContainer.mainContext.insert(offlineLyrics)
                }
            }
        }
        
        NotificationCenter.default.post(name: OfflineManager.trackDownloadStatusChanged, object: track.id)
    }
    
    @MainActor
    func delete(_ track: OfflineTrack) {
        DownloadManager.shared.deleteTrack(trackId: track.id)
        PersistenceManager.shared.modelContainer.mainContext.delete(track)
        NotificationCenter.default.post(name: OfflineManager.trackDownloadStatusChanged, object: track.id)
    }
}

// MARK: Get/Set

extension OfflineManager {
    @MainActor
    func getOfflineTrack(trackId: String) -> OfflineTrack? {
        var track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.id == trackId })
        track.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(track).first
    }
    
    @MainActor
    func getOfflineTrack(taskId: Int) -> OfflineTrack? {
        var track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId == taskId })
        track.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(track).first
    }
    
    @MainActor
    func getUnfinishedDownloads() throws -> [OfflineTrack] {
        let track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId != nil })
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(track)
    }
    
    @MainActor
    func getTrackOfflineStatus(trackId: String) -> Item.OfflineStatus {
        if let track = getOfflineTrack(trackId: trackId) {
            return track.downloadId == nil ? .downloaded : .working
        }
        
        return .none
    }
    
    @MainActor
    public func getLyrics(trackId: String) -> Track.Lyrics? {
        var lyrics = FetchDescriptor<OfflineLyrics>(predicate: #Predicate { $0.trackId == trackId })
        lyrics.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(lyrics).first?.lyrics
    }
}

// MARK: Provider

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
