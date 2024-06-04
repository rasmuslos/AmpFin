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

// MARK: Private

extension OfflineManager {
    @MainActor
    func download(track: Track) {
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
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineItem)
        downloadTask.resume()
        
        Task.detached {
            await updateLyrics(trackId: track.id)
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
    func offlineTrack(trackId: String) throws -> OfflineTrack {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.id == trackId })
        descriptor.fetchLimit = 1
        
        guard let track = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first else {
            throw OfflineError.notFound
        }
        
        return track
    }
    
    @MainActor
    func offlineTrack(taskId taskIdentifier: Int) throws -> OfflineTrack {
        var track = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId == taskIdentifier })
        track.fetchLimit = 1
        
        guard let track = try? PersistenceManager.shared.modelContainer.mainContext.fetch(track).first else {
            throw OfflineError.notFound
        }
        
        return track
    }
    
    @MainActor
    func offlineTracks() throws -> [OfflineTrack] {
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor())
    }
    
    func updateLyrics(trackId: String) async {
        guard let lyrics = try? await JellyfinClient.shared.lyrics(trackId: trackId) else {
            return
        }
        
        await MainActor.run {
            try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflineLyrics.self, where: #Predicate {
                $0.trackIdentifier == trackId
            })
            let offlineLyrics = OfflineLyrics(trackIdentifier: trackId, contents: lyrics)
            PersistenceManager.shared.modelContainer.mainContext.insert(offlineLyrics)
        }
    }
}

// MARK: Public

public extension OfflineManager {
    @MainActor
    func track(identifier: String) throws -> Track {
        let track = try offlineTrack(trackId: identifier)
        return Track(track)
    }
    
    @MainActor
    func tracks(favoriteOnly: Bool = false) throws -> [Track] {
        let descriptor: FetchDescriptor<OfflineTrack>
        
        if favoriteOnly {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.favorite == true })
        } else {
            descriptor = FetchDescriptor()
        }
        
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        return tracks.map(Track.init)
    }
    
    @MainActor
    func tracks(search: String) throws -> [Track] {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate {
            $0.name.localizedStandardContains(search)
        })
        descriptor.fetchLimit = 20
        
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).map(Track.init)
    }
    
    @MainActor
    func downloading() throws -> [Track] {
        let descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadId != nil })
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        
        return tracks.map(Track.init)
    }
    
    @MainActor
    func offlineStatus(trackId: String) -> ItemOfflineTracker.OfflineStatus {
        guard let track = try? offlineTrack(trackId: trackId) else {
            return .none
        }
        
        return track.downloadId == nil ? .downloaded : .working
    }
    
    @MainActor
    func lyrics(trackId: String, allowUpdate: Bool = false) throws -> Track.Lyrics {
        if allowUpdate {
            Task.detached {
                await updateLyrics(trackId: trackId)
            }
        }
        
        var descriptor = FetchDescriptor<OfflineLyrics>(predicate: #Predicate { $0.trackIdentifier == trackId })
        descriptor.fetchLimit = 1
        
        guard let entity = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first else {
            throw OfflineError.notFound
        }
        
        return entity.contents
    }
    
    @MainActor
    func update(trackId: String) throws {
        let track = try offlineTrack(trackId: trackId)
        let downloadTask = DownloadManager.shared.download(trackId: trackId)
        
        track.downloadId = downloadTask.taskIdentifier
        downloadTask.resume()
        
        Task.detached {
            await updateLyrics(trackId: trackId)
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: track.id)
    }
}
