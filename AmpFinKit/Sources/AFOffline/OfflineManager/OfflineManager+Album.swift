//
//  OfflineManager+Album.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFFoundation
import AFNetwork

// MARK: Internal (Helper)

internal extension OfflineManager {
    func create(album: Album, tracks: [Track], context: ModelContext) throws -> OfflineAlbum {
        if let cover = album.cover {
            Task.detached {
                try await DownloadManager.shared.downloadCover(parentId: album.id, cover: cover)
            }
        }
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let offlineAlbum = OfflineAlbum(
            id: album.id,
            name: album.name,
            overview: album.overview,
            genres: album.genres,
            released: album.releaseDate,
            artists: album.artists.map { .init(artistIdentifier: $0.id, artistName: $0.name) },
            favorite: album._favorite,
            childrenIdentifiers: tracks.map { $0.id })
        
        context.insert(offlineAlbum)
        try context.save()
        
        return offlineAlbum
    }
    
    func delete(offlineAlbum: OfflineAlbum, context: ModelContext) throws {
        context.delete(offlineAlbum)
        
        try? DownloadManager.shared.deleteCover(parentId: offlineAlbum.id)
        try removeOrphans(context: context)
        
        
        try context.save()
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: offlineAlbum.id)
    }
    
    func offlineAlbum(albumId identifier: String, context: ModelContext) throws -> OfflineAlbum {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineAlbum> { $0.id == identifier })
        descriptor.fetchLimit = 1
        
        guard let album = try context.fetch(descriptor).first else {
            throw OfflineError.notFound
        }
        
        return album
    }
    
    func offlineAlbums(context: ModelContext) throws -> [OfflineAlbum] {
        return try context.fetch(.init())
    }
}

// MARK: Public (Higher Order)

public extension OfflineManager {
    func download(album: Album) async throws {
        let tracks = try await JellyfinClient.shared.tracks(albumId: album.id)
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let offlineAlbum: OfflineAlbum
        
        if let existing = try? self.offlineAlbum(albumId: album.id, context: context) {
            offlineAlbum = existing
            offlineAlbum.childrenIdentifiers = tracks.map { $0.id }
        } else {
            offlineAlbum = try create(album: album, tracks: tracks, context: context)
        }
        
        for track in tracks {
            download(track: track, context: context)
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: album.id)
    }
    
    func delete(albumId identifier: String) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let album = try OfflineManager.shared.offlineAlbum(albumId: identifier, context: context)
        
        try delete(offlineAlbum: album, context: context)
    }
    
    func albumCount() throws -> Int {
        try ModelContext(PersistenceManager.shared.modelContainer).fetchCount(FetchDescriptor<OfflineAlbum>())
    }
    
    func albums(limit: Int, offset: Int) throws -> [Album] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        var descriptor = FetchDescriptor<OfflineAlbum>()
        
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        return try context.fetch(descriptor).map(Album.init)
    }
    
    func albums(search: String) throws -> [Album] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        var descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate {
            $0.name.localizedStandardContains(search)
        })
        descriptor.fetchLimit = 20
        
        return try context.fetch(descriptor).map(Album.init)
    }
    
    func recentAlbums() throws -> [Album] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        var descriptor = FetchDescriptor<OfflineAlbum>()
        
        descriptor.fetchLimit = 20
        descriptor.fetchOffset = max(0, try albumCount() - 20)
        
        return try context.fetch(descriptor).map(Album.init)
    }
    
    func randomAlbums() throws -> [Album] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let albumCount = try context.fetchCount(FetchDescriptor<OfflineAlbum>())
        let amount = min(20, albumCount)
        
        var albums = [Album]()
        while albums.count < amount {
            var descriptor = FetchDescriptor<OfflineAlbum>()
            descriptor.fetchLimit = 1
            descriptor.fetchOffset = Int.random(in: 0..<amount)
            
            if let album = try? context.fetch(descriptor).first {
                if albums.contains(where: { $0.id == album.id }) {
                    continue
                }
                
                albums.append(Album(album))
            } else {
                break
            }
        }
        
        return albums
    }
    
    func tracks(albumId identifier: String) throws -> [Track] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        let album = try offlineAlbum(albumId: identifier, context: context)
        let tracks = try offlineTracks(parent: album, context: context)
        
        return tracks.map { Track($0, parent: album) }
    }
    
    func album(identifier: String) throws -> Album {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let album = try offlineAlbum(albumId: identifier, context: context)
        
        return Album(album)
    }
    
    func offlineStatus(albumId identifier: String) -> ItemOfflineTracker.OfflineStatus {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        do {
            let album = try offlineAlbum(albumId: identifier, context: context)
            let inProgress = try downloadInProgress(parent: album, context: context)
            
            return inProgress ? .working : .downloaded
        } catch {
            return .none
        }
    }
}
