//
//  OfflineManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFFoundation
import AFNetwork

// MARK: Internal (Higher order)

internal extension OfflineManager {
    func updateLyrics(trackId: String) async {
        guard let lyrics = try? await JellyfinClient.shared.lyrics(trackId: trackId) else {
            return
        }
        
        await Task.yield()
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let offlineLyrics = OfflineLyrics(trackIdentifier: trackId, contents: lyrics)
        
        try? context.delete(model: OfflineLyrics.self, where: #Predicate {
            $0.trackIdentifier == trackId
        })
        
        context.insert(offlineLyrics)
        try? context.save()
    }
}

// MARK: Internal (Helper)

internal extension OfflineManager {
    func download(track: Track, context: ModelContext) {
        guard offlineStatus(trackId: track.id) == .none else {
            return
        }
        
        let downloadTask = DownloadManager.shared.download(trackId: track.id)
        
        let offlineItem = OfflineTrack(
            id: track.id,
            name: track.name,
            released: track.releaseDate,
            album: .init(albumIdentifier: track.album.id, albumName: track.album.name, albumArtists: track.album.artists.map { .init(artistIdentifier: $0.id, artistName: $0.name) }),
            artists: track.artists.map { .init(artistIdentifier: $0.id, artistName: $0.name) },
            favorite: track._favorite,
            runtime: track.runtime,
            downloadId: downloadTask.taskIdentifier)
        
        context.insert(offlineItem)
        try? context.save()
        
        downloadTask.resume()
        
        Task.detached {
            await updateLyrics(trackId: track.id)
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: track.id)
    }
    
    func delete(track: OfflineTrack, context: ModelContext) {
        DownloadManager.shared.delete(trackId: track.id)
        context.delete(track)
        try? context.save()
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: track.id)
    }
    
    func offlineTrack(trackId: String, context: ModelContext) throws -> OfflineTrack {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.id == trackId })
        descriptor.fetchLimit = 1
        
        guard let track = try context.fetch(descriptor).first else {
            throw OfflineError.notFound
        }
        
        return track
    }
    
    func offlineTrack(taskId taskIdentifier: Int, context: ModelContext) throws -> OfflineTrack {
        var track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId == taskIdentifier })
        track.fetchLimit = 1
        
        guard let track = try context.fetch(track).first else {
            throw OfflineError.notFound
        }
        
        return track
    }
    
    func offlineTracks(context: ModelContext) throws -> [OfflineTrack] {
        return try context.fetch(FetchDescriptor())
    }
}

// MARK: Public (Higher Order)

public extension OfflineManager {
    func track(identifier: String) throws -> Track {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let track = try offlineTrack(trackId: identifier, context: context)
        
        return Track(track)
    }
    
    func trackCount() throws -> Int {
        try ModelContext(PersistenceManager.shared.modelContainer).fetchCount(FetchDescriptor<OfflineTrack>())
    }
    
    func tracks(favoriteOnly: Bool, limit: Int, offset: Int) throws -> [Track] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        var descriptor: FetchDescriptor<OfflineTrack>
        
        if favoriteOnly {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.favorite == true })
        } else {
            descriptor = FetchDescriptor()
        }
        
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        return try context.fetch(descriptor).map(Track.init)
    }
    func tracks(search: String) throws -> [Track] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate {
            $0.name.localizedStandardContains(search)
        })
        descriptor.fetchLimit = 20
        
        return try context.fetch(descriptor).map(Track.init)
    }
    
    func downloading() throws -> [Track] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        let descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId != nil })
        let tracks = try context.fetch(descriptor)
        
        return tracks.map(Track.init)
    }
    
    func offlineStatus(trackId: String) -> ItemOfflineTracker.OfflineStatus {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        guard let track = try? offlineTrack(trackId: trackId, context: context) else {
            return .none
        }
        
        return track.downloadId == nil ? .downloaded : .working
    }
    
    func lyrics(trackId: String, allowUpdate: Bool = false) throws -> Track.Lyrics {
        if allowUpdate {
            Task.detached {
                await updateLyrics(trackId: trackId)
            }
        }
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        var descriptor = FetchDescriptor<OfflineLyrics>(predicate: #Predicate { $0.trackIdentifier == trackId })
        descriptor.fetchLimit = 1
        
        guard let entity = try context.fetch(descriptor).first else {
            throw OfflineError.notFound
        }
        
        return entity.contents
    }
    
    func update(trackId: String) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        let track = try offlineTrack(trackId: trackId, context: context)
        let downloadTask = DownloadManager.shared.download(trackId: trackId)
        
        track.downloadId = downloadTask.taskIdentifier
        downloadTask.resume()
        
        Task.detached {
            await updateLyrics(trackId: trackId)
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: track.id)
    }
    
    func updateLastPlayed(trackId: String, date: Date = .now) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let track = try offlineTrack(trackId: trackId, context: context)
        
        track.lastPlayed = date
        try context.save()
    }
}
