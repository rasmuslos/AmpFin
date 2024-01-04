//
//  OfflineManager+Album.swift
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
    func create(album: Album, tracks: [Track]) async throws -> OfflineAlbum {
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
            releaseDate: album.releaseDate,
            artists: album.artists,
            favorite: album.favorite,
            childrenIds: tracks.map { $0.id })
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineAlbum)
        return offlineAlbum
    }
    
    @MainActor
    func delete(offlineAlbum: OfflineAlbum) throws {
        PersistenceManager.shared.modelContainer.mainContext.delete(offlineAlbum)
        
        try? DownloadManager.shared.deleteCover(parentId: offlineAlbum.id)
        try removeOrphanedTracks()
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: offlineAlbum.id)
    }
    
    @MainActor
    func getOfflineAlbum(albumId: String) throws -> OfflineAlbum {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineAlbum> { $0.id == albumId })
        descriptor.fetchLimit = 1
        
        if let album = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return album
        }
        
        throw OfflineError.notFoundError
    }
    
    @MainActor
    func getOfflineAlbums() throws -> [OfflineAlbum] {
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor())
    }
}

// MARK: Public

public extension OfflineManager {
    func download(album: Album) async throws {
        let offlineAlbum: OfflineAlbum
        let tracks = try await JellyfinClient.shared.getTracks(albumId: album.id)
        
        if let existing = try? await getOfflineAlbum(albumId: album.id) {
            offlineAlbum = existing
            offlineAlbum.childrenIds = tracks.map { $0.id }
        } else {
            offlineAlbum = try await create(album: album, tracks: tracks)
        }
        
        for track in tracks {
            Task.detached {
                await download(track: track)
            }
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: album.id)
    }
    
    @MainActor
    func delete(albumId: String) throws {
        let album = try OfflineManager.shared.getOfflineAlbum(albumId: albumId)
        try delete(offlineAlbum: album)
    }
    
    @MainActor
    func getAlbums() throws -> [Album] {
        return try getOfflineAlbums().map(Album.convertFromOffline)
    }
    
    @MainActor
    func getAlbums(query: String) throws -> [Album] {
        let albums = Array(try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineAlbum>()).filter {
            $0.name.localizedStandardContains(query)
            || $0.artists.reduce(false, { $0 || $1.name.localizedStandardContains(query) })
        }.prefix(20))
        
        return albums.map(Album.convertFromOffline)
    }
    
    @MainActor
    func getRecentAlbums() throws -> [Album] {
        let albums = try getAlbums()
        return albums.suffix(20).reversed()
    }
    
    @MainActor
    func getTracks(albumId: String) throws -> [Track] {
        let album = try getOfflineAlbum(albumId: albumId)
        let tracks = try getOfflineTracks(parent: album)
        
        return tracks.map { Track.convertFromOffline($0, parent: album) }
    }
    
    @MainActor
    func getAlbum(albumId: String) throws -> Album {
        let album = try getOfflineAlbum(albumId: albumId)
        return Album.convertFromOffline(album)
    }
    
    @MainActor
    func getOfflineStatus(albumId: String) -> ItemOfflineTracker.OfflineStatus {
        do {
            let album = try getOfflineAlbum(albumId: albumId)
            let inProgress = try isDownloadInProgress(parent: album)
            
            return inProgress ? .working : .downloaded
        } catch {
            return .none
        }
    }
    
    @MainActor
    func isAlbumDownloaded(albumId: String) -> Bool {
        (try? getOfflineAlbum(albumId: albumId)) != nil
    }
}
