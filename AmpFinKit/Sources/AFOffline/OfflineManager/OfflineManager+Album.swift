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

extension OfflineManager {
    @MainActor
    func create(album: Album, tracks: [Track]) throws -> OfflineAlbum {
        if let cover = album.cover {
            Task.detached {
                try await DownloadManager.shared.downloadCover(parentId: album.id, cover: cover)
            }
        }
        
        let offlineAlbum = OfflineAlbum(
            id: album.id,
            name: album.name,
            overview: album.overview,
            genres: album.genres,
            released: album.releaseDate,
            artists: album.artists.map { .init(artistIdentifier: $0.id, artistName: $0.name) },
            favorite: album._favorite,
            childrenIdentifiers: tracks.map { $0.id })
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineAlbum)
        return offlineAlbum
    }
    
    @MainActor
    func delete(offlineAlbum: OfflineAlbum) throws {
        PersistenceManager.shared.modelContainer.mainContext.delete(offlineAlbum)
        
        try? DownloadManager.shared.deleteCover(parentId: offlineAlbum.id)
        try removeOrphans()
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: offlineAlbum.id)
    }
    
    @MainActor
    func offlineAlbum(albumId identifier: String) throws -> OfflineAlbum {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineAlbum> { $0.id == identifier })
        descriptor.fetchLimit = 1
        
        guard let album = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first else {
            throw OfflineError.notFound
        }
        
        return album
    }
    
    @MainActor
    func offlineAlbums() throws -> [OfflineAlbum] {
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(.init())
    }
}

public extension OfflineManager {
    func download(album: Album) async throws {
        let offlineAlbum: OfflineAlbum
        let tracks = try await JellyfinClient.shared.tracks(albumId: album.id)
        
        if let existing = try? await self.offlineAlbum(albumId: album.id) {
            offlineAlbum = existing
            
            await MainActor.run {
                offlineAlbum.childrenIdentifiers = tracks.map { $0.id }
            }
        } else {
            offlineAlbum = try await create(album: album, tracks: tracks)
        }
        
        for track in tracks {
            Task {
                await download(track: track)
            }
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: album.id)
    }
    
    @MainActor
    func delete(albumId identifier: String) throws {
        let album = try OfflineManager.shared.offlineAlbum(albumId: identifier)
        try delete(offlineAlbum: album)
    }
    
    @MainActor
    func albums() throws -> [Album] {
        return try offlineAlbums().map(Album.init)
    }
    
    @MainActor
    func albums(search: String) throws -> [Album] {
        var descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate {
            $0.name.localizedStandardContains(search)
        })
        descriptor.fetchLimit = 20
        
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).map(Album.init)
    }
    
    @MainActor
    func recentAlbums() throws -> [Album] {
        let albums = try albums()
        return albums.suffix(20).reversed()
    }
    
    @MainActor
    func randomAlbums() throws -> [Album] {
        let albumCount = try PersistenceManager.shared.modelContainer.mainContext.fetchCount(FetchDescriptor<OfflineAlbum>())
        let amount = min(20, albumCount)
        
        var albums = [Album]()
        while albums.count < amount {
            var descriptor = FetchDescriptor<OfflineAlbum>()
            descriptor.fetchLimit = 1
            descriptor.fetchOffset = Int.random(in: 0..<amount)
            
            if let album = try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
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
    
    @MainActor
    func tracks(albumId identifier: String) throws -> [Track] {
        let album = try offlineAlbum(albumId: identifier)
        let tracks = try offlineTracks(parent: album)
        
        return tracks.map { Track($0, parent: album) }
    }
    
    @MainActor
    func album(identifier: String) throws -> Album {
        let album = try offlineAlbum(albumId: identifier)
        return Album(album)
    }
    
    @MainActor
    func offlineStatus(albumId identifier: String) -> ItemOfflineTracker.OfflineStatus {
        do {
            let album = try offlineAlbum(albumId: identifier)
            let inProgress = try downloadInProgress(parent: album)
            
            return inProgress ? .working : .downloaded
        } catch {
            return .none
        }
    }
}
