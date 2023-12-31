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
    func create(album: Album, trackCount: Int) async throws -> OfflineAlbum {
        if let cover = album.cover {
            try await DownloadManager.shared.downloadCover(albumId: album.id, cover: cover)
        }
        
        let offlineAlbum = OfflineAlbum(
            id: album.id,
            name: album.name,
            overview: album.overview,
            genres: album.genres,
            releaseDate: album.releaseDate,
            artists: album.artists,
            favorite: album.favorite,
            trackCount: trackCount)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineAlbum)
        return offlineAlbum
    }
    
    @MainActor
    func delete(album: OfflineAlbum) throws {
        let tracks = try getOfflineTracks(albumId: album.id)
        for track in tracks {
            delete(track: track)
        }
        
        try? DownloadManager.shared.deleteCover(albumId: album.id)
        PersistenceManager.shared.modelContainer.mainContext.delete(album)
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: album.id)
    }
    
    @MainActor
    func getOfflineAlbum(albumId: String) -> OfflineAlbum? {
        var album = FetchDescriptor(predicate: #Predicate<OfflineAlbum> { $0.id == albumId })
        album.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(album).first
    }
    
    @MainActor
    func getOfflineTracks(albumId: String) throws -> [OfflineTrack] {
        // this is so incredibly stupid... whoever thought of this goes straight to hell
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineTrack>())
        return tracks.filter { $0.album.id == albumId }
    }
    
    @MainActor
    func isDownloadInProgress(albumId: String) throws -> Bool {
        let tracks = try getOfflineTracks(albumId: albumId)
        return tracks.reduce(false) { $1.downloadId == nil ? $0 : true }
    }
}

// MARK: Public

public extension OfflineManager {
    func download(_ album: Album) async throws {
        var offlineAlbum: OfflineAlbum
        let tracks = try await JellyfinClient.shared.getTracks(albumId: album.id)
        
        if let existing = await getOfflineAlbum(albumId: album.id) {
            offlineAlbum = existing
        } else {
            offlineAlbum = try await create(album: album, trackCount: tracks.count)
        }
        
        let album = offlineAlbum
        
        tracks.forEach { track in
            Task.detached {
                await download(track: track, album: album)
            }
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: album.id)
    }
    
    @MainActor
    func delete(albumId: String) throws {
        if let album = OfflineManager.shared.getOfflineAlbum(albumId: albumId) {
            try delete(album: album)
        } else {
            throw OfflineError.notFoundError
        }
    }
    
    @MainActor
    func getAlbums() throws -> [Album] {
        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineAlbum>())
        return albums.map(Album.convertFromOffline)
    }
    
    @MainActor
    func getAlbums(query: String) throws -> [Album] {
        var descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate { $0.name.localizedStandardContains(query) })
        descriptor.fetchLimit = 20
        
        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        return albums.map(Album.convertFromOffline)
    }
    
    @MainActor
    func getRecentAlbums() throws -> [Album] {
        // this is stupid
        let albums = try getAlbums()
        return albums.suffix(20).reversed()
    }
    
    @MainActor
    func getTracks(albumId: String) throws -> [Track] {
        return try getOfflineTracks(albumId: albumId).map(Track.convertFromOffline)
    }
    
    @MainActor
    func getAlbum(albumId: String) -> Album? {
        var descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate { $0.id == albumId })
        descriptor.fetchLimit = 1
        
        if let album = try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return Album.convertFromOffline(album)
        } else {
            return nil
        }
    }
    
    @MainActor
    func getOfflineStatus(albumId: String) -> ItemOfflineTracker.OfflineStatus {
        do {
            return try isDownloadInProgress(albumId: albumId) ? .working : .downloaded
        } catch {}
        
        return .none
    }
}
