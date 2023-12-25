//
//  OfflineManager+Album.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFBaseKit

// MARK: Downloader

public extension OfflineManager {
    func download(_ album: Album) async throws {
        var offlineAlbum: OfflineAlbum
        let tracks = try await JellyfinClient.shared.getTracks(albumId: album.id)
        
        if let existing = await getOfflineAlbum(albumId: album.id) {
            offlineAlbum = existing
        } else {
            offlineAlbum = try await createOfflineAlbum(album, trackCount: tracks.count)
        }
        
        let album = offlineAlbum
        
        tracks.forEach { track in
            Task.detached {
                await download(track, album: album)
            }
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: album.id)
    }
    
    @MainActor
    func getAlbumOfflineStatus(albumId: String) -> ItemOfflineTracker.OfflineStatus {
        if let album = getOfflineAlbum(albumId: albumId) {
            return isAlbumDownloadInProgress(album) ? .working : .downloaded
        }
        
        return .none
    }
}

// MARK: Get/Set/Delete

extension OfflineManager {
    @MainActor
    func getOfflineAlbum(albumId: String) -> OfflineAlbum? {
        var album = FetchDescriptor(predicate: #Predicate<OfflineAlbum> { $0.id == albumId })
        album.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(album).first
    }
    
    @MainActor
    func createOfflineAlbum(_ album: Album, trackCount: Int) async throws -> OfflineAlbum {
        if let cover = album.cover {
            try await DownloadManager.shared.downloadAlbumCover(albumId: album.id, cover: cover)
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
    public func delete(albumId: String) throws {
        if let album = OfflineManager.shared.getOfflineAlbum(albumId: albumId) {
            try delete(album)
        } else {
            throw OfflineError.notFoundError
        }
    }
    
    @MainActor
    func delete(_ album: OfflineAlbum) throws {
        let tracks = try getAlbumTracks(album)
        for track in tracks {
            delete(track)
        }
        
        try? DownloadManager.shared.deleteAlbumCover(albumId: album.id)
        PersistenceManager.shared.modelContainer.mainContext.delete(album)
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: album.id)
    }
    
    @MainActor
    public func getAlbumTracks(albumId: String) throws -> [Track] {
        if let album = OfflineManager.shared.getOfflineAlbum(albumId: albumId) {
            return try OfflineManager.shared.getAlbumTracks(album).map(Track.convertFromOffline)
        }
        
        throw OfflineError.notFoundError
    }
}

// MARK: Album tracks

extension OfflineManager {
    @MainActor
    func getAlbumTracks(_ album: OfflineAlbum) throws -> [OfflineTrack] {
        // this is so incredibly stupid... whoever thought of this goes straight to hell
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineTrack>())
        return tracks.filter { $0.album.id == album.id }
    }
    
    @MainActor
    func isAlbumDownloadInProgress(_ album: OfflineAlbum) -> Bool {
        let tracks = (try? getAlbumTracks(album)) ?? []
        return tracks.reduce(false) { $1.downloadId == nil ? $0 : true }
    }
}

// MARK: Provider

public extension OfflineManager {
    @MainActor
    func getRecentAlbums() throws -> [Album] {
        let descriptor = FetchDescriptor<OfflineAlbum>()
        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        
        // this is also stupid
        return albums.suffix(20).map(Album.convertFromOffline).reversed()
    }
    
    @MainActor
    func getAllAlbums() throws -> [Album] {
        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineAlbum>())
        return albums.map(Album.convertFromOffline)
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
    
    @MainActor func searchAlbums(query: String) throws -> [Album] {
        var descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate { $0.name.localizedStandardContains(query) })
        descriptor.fetchLimit = 20
        
        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        return albums.map(Album.convertFromOffline)
    }
}
