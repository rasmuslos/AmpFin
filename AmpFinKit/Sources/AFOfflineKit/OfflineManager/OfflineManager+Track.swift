//
//  OfflineManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFBaseKit

// MARK: Private

extension OfflineManager {
    @MainActor
    func download(track: Track) {
        if let existing = try? getOfflineTrack(trackId: track.id) {
            return
        }
        
        let downloadTask = DownloadManager.shared.download(track: track)
        
        let offlineItem = OfflineTrack(
            id: track.id,
            name: track.name,
            releaseDate: track.releaseDate,
            album: track.album,
            artists: track.artists,
            favorite: track.favorite,
            runtime: track.runtime,
            downloadId: downloadTask.taskIdentifier)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineItem)
        downloadTask.resume()
        
        Task.detached {
            if let lyrics = try? await JellyfinClient.shared.getLyrics(trackId: track.id) {
                Task.detached { @MainActor in
                    let offlineLyrics = OfflineLyrics(trackId: track.id, lyrics: lyrics)
                    PersistenceManager.shared.modelContainer.mainContext.insert(offlineLyrics)
                }
            }
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: track.id)
    }
    
    @MainActor
    func delete(track: OfflineTrack) {
        DownloadManager.shared.delete(trackId: track.id)
        PersistenceManager.shared.modelContainer.mainContext.delete(track)
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: track.id)
    }
    
    @MainActor
    func getOfflineTrack(trackId: String) throws -> OfflineTrack {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.id == trackId })
        descriptor.fetchLimit = 1
        
        if let track = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return track
        }
        
        throw OfflineError.notFoundError
    }
    
    @MainActor
    func getOfflineTrack(taskId: Int) throws -> OfflineTrack {
        var track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId == taskId })
        track.fetchLimit = 1
        
        if let track = try? PersistenceManager.shared.modelContainer.mainContext.fetch(track).first {
            return track
        }
        
        throw OfflineError.notFoundError
    }
    
    @MainActor
    func getOfflineTracks() throws -> [OfflineTrack] {
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor())
    }
    
    @MainActor
    func getUnfinishedDownloads() throws -> [OfflineTrack] {
        let track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId != nil })
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(track)
    }
}

// MARK: Public

public extension OfflineManager {
    @MainActor
    func getTracks(favorite: Bool = false) throws -> [Track] {
        let descriptor: FetchDescriptor<OfflineTrack>
        
        if favorite {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.favorite == true })
        } else {
            descriptor = FetchDescriptor()
        }
        
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        return tracks.map(Track.convertFromOffline)
    }
    
    @MainActor
    func getTracks(query: String) throws -> [Track] {
        // SwiftData has serious flaws
        let tracks = try getOfflineTracks().filter {
            $0.name.localizedStandardContains(query)
            || $0.artists.map { $0.name }.reduce(false, { $0 || $1.localizedStandardContains(query) })
        }
        
        return tracks.map(Track.convertFromOffline)
    }
    
    @MainActor
    func getDownloadingTracks() throws -> [Track] {
        let tracks = try getUnfinishedDownloads()
        return tracks.map(Track.convertFromOffline)
    }
    
    @MainActor
    func getOfflineStatus(trackId: String) -> ItemOfflineTracker.OfflineStatus {
        if let track = try? getOfflineTrack(trackId: trackId) {
            return track.downloadId == nil ? .downloaded : .working
        }
        
        return .none
    }
    
    @MainActor
    func getLyrics(trackId: String) -> Track.Lyrics? {
        var lyrics = FetchDescriptor<OfflineLyrics>(predicate: #Predicate { $0.trackId == trackId })
        lyrics.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(lyrics).first?.lyrics
    }
}
