//
//  OfflineManager+Album.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData

// MARK: Downloader

extension OfflineManager {
    func downloadAlbum(_ album: Album) async throws {
        var offlineAlbum: OfflineAlbum
        let tracks = try await JellyfinClient.shared.getAlbumTracks(id: album.id)
        
        if let existing = await getOfflineAlbum(albumId: album.id) {
            offlineAlbum = existing
        } else {
            offlineAlbum = try await createOfflineAlbum(album, trackCount: tracks.count)
        }
        
        let album = offlineAlbum
        
        tracks.forEach { track in
            Task.detached {
                await downloadTrack(track, album: album)
            }
        }
        
        NotificationCenter.default.post(name: NSNotification.AlbumDownloadStatusChanged, object: nil)
    }
    
    @MainActor
    func getAlbumOfflineStatus(albumId: String) async -> Item.OfflineStatus {
        if let album = getOfflineAlbum(albumId: albumId) {
            return await isAlbumDownloadInProgress(album) ? .working : .downloaded
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
            sortName: album.sortName?.lowercased() ?? album.name.lowercased(),
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
    func deleteOfflineAlbum(_ album: OfflineAlbum) throws {
        let tracks = try getAlbumTracks(album)
        for track in tracks {
            deleteOfflineTrack(track)
        }
        
        try DownloadManager.shared.deleteAlbumCover(albumId: album.id)
        PersistenceManager.shared.modelContainer.mainContext.delete(album)
        
        NotificationCenter.default.post(name: NSNotification.AlbumDownloadStatusChanged, object: nil)
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
    
    func isAlbumDownloadInProgress(_ album: OfflineAlbum) async -> Bool {
        let tracks = (try? await getAlbumTracks(album)) ?? []
        return tracks.reduce(false) { $1.downloadId == nil ? $0 : true }
    }
}

// MARK: Provider

extension OfflineManager {
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
    func getAlbumById(_ albumId: String) throws -> Album? {
        var descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate { $0.id == albumId })
        descriptor.fetchLimit = 1
        
        if let album = try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return Album.convertFromOffline(album)
        } else {
            return nil
        }
    }
    
    @MainActor func searchAlbums(query: String) throws -> [Album] {
        var descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate { $0.sortName.contains(query) })
        descriptor.fetchLimit = 20
        
        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        return albums.map(Album.convertFromOffline)
    }
}
