//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftData
import AFFoundation
import AFNetwork

extension OfflineManager {
    @MainActor
    func create(playlist: Playlist, tracks: [Track]) throws -> OfflinePlaylist {
        if let cover = playlist.cover {
            Task.detached {
                try await DownloadManager.shared.downloadCover(parentId: playlist.id, cover: cover)
            }
        }
        
        let albumIds = Set(tracks.map { $0.album.id })
        for albumId in albumIds {
            if !DownloadManager.shared.coverDownloaded(parentId: albumId) {
                Task.detached {
                    try await DownloadManager.shared.downloadCover(parentId: albumId, cover: Cover(type: .remote, size: .normal, url: Cover.url(itemId: albumId, imageTag: nil)))
                }
            }
        }
        
        let offlinePlaylist = OfflinePlaylist(
            id: playlist.id,
            name: playlist.name,
            favorite: playlist._favorite,
            duration: playlist.duration,
            childrenIdentifiers: tracks.map { $0.id })
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlinePlaylist)
        return offlinePlaylist
    }
    
    @MainActor
    func delete(playlist: OfflinePlaylist) throws {
        PersistenceManager.shared.modelContainer.mainContext.delete(playlist)
        
        try? DownloadManager.shared.deleteCover(parentId: playlist.id)
        try removeOrphans()
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: playlist.id)
    }
    
    @MainActor
    func offlinePlaylist(playlistId identifier: String) throws -> OfflinePlaylist {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflinePlaylist> { $0.id == identifier })
        descriptor.fetchLimit = 1
        
        guard let playlist = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first else {
            throw OfflineError.notFound
        }
        
        return playlist
    }
    
    @MainActor
    func offlinePlaylists() throws -> [OfflinePlaylist] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor())
    }
}

public extension OfflineManager {
    func download(playlist: Playlist) async throws {
        let offlinePlaylist: OfflinePlaylist
        let tracks = try await JellyfinClient.shared.tracks(playlistId: playlist.id)
        
        if let existing = try? await self.offlinePlaylist(playlistId: playlist.id) {
            offlinePlaylist = existing
            offlinePlaylist.childrenIdentifiers = tracks.map { $0.id }
        } else {
            offlinePlaylist = try await create(playlist: playlist, tracks: tracks)
        }
        
        for track in tracks {
            Task {
                await download(track: track)
            }
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: offlinePlaylist.id)
    }
    
    @MainActor
    func delete(playlistId identifier: String) throws {
        let playlist = try OfflineManager.shared.offlinePlaylist(playlistId: identifier)
        try delete(playlist: playlist)
    }
    
    @MainActor
    func playlist(playlistId identifier: String) throws -> Playlist {
        let playlist = try offlinePlaylist(playlistId: identifier)
        return Playlist(playlist)
    }
    
    @MainActor
    func playlists() throws -> [Playlist] {
        try offlinePlaylists().map(Playlist.init)
    }
    
    @MainActor
    func tracks(playlistId identifier: String) throws -> [Track] {
        let playlist = try offlinePlaylist(playlistId: identifier)
        let tracks = try offlineTracks(parent: playlist)
        
        return tracks.map { Track($0, parent: playlist) }
    }
    
    @MainActor
    func offlineStatus(playlistId identifier: String) -> ItemOfflineTracker.OfflineStatus {
        do {
            let playlist = try offlinePlaylist(playlistId: identifier)
            let inProgress = try downloadInProgress(parent: playlist)
            
            return inProgress ? .working : .downloaded
        } catch {
            return .none
        }
    }
}
