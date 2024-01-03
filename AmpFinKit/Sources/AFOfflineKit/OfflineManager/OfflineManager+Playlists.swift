//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftData
import AFBaseKit

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
            if !DownloadManager.shared.isCoverDownloaded(parentId: albumId) {
                Task.detached {
                    try await DownloadManager.shared.downloadCover(parentId: albumId, cover: Item.Cover(type: .remote, url: Item.Cover.constructItemCoverUrl(itemId: albumId, imageTag: nil)))
                }
            }
        }
        
        let offlinePlaylist = OfflinePlaylist(
            id: playlist.id,
            name: playlist.name,
            favorite: playlist.favorite,
            duration: playlist.duration,
            childrenIds: tracks.map { $0.id })
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlinePlaylist)
        return offlinePlaylist
    }
    
    @MainActor
    func delete(playlist: OfflinePlaylist) throws {
        try delete(parent: playlist)
        
        try? DownloadManager.shared.deleteCover(parentId: playlist.id)
        PersistenceManager.shared.modelContainer.mainContext.delete(playlist)
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: playlist.id)
    }
    
    @MainActor
    func getOfflinePlaylists() throws -> [OfflinePlaylist] {
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor())
    }
    
    @MainActor
    func getOfflinePlaylist(playlistId: String) throws -> OfflinePlaylist {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflinePlaylist> { $0.id == playlistId })
        descriptor.fetchLimit = 1
        
        if let playlist = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return playlist
        }
        
        throw OfflineManager.OfflineError.notFoundError
    }
    
    @MainActor
    func getOfflineStatus(playlistId: String) -> ItemOfflineTracker.OfflineStatus {
        do {
            let playlist = try getOfflinePlaylist(playlistId: playlistId)
            let inProgress = try isDownloadInProgress(parent: playlist)
            
            return inProgress ? .working : .downloaded
        } catch {
            return .none
        }
    }
}

public extension OfflineManager {
    func download(playlist: Playlist) async throws {
        let offlinePlaylist: OfflinePlaylist
        let tracks = try await JellyfinClient.shared.getTracks(playlistId: playlist.id)
        
        if let existing = try? await getOfflinePlaylist(playlistId: playlist.id) {
            offlinePlaylist = existing
            await update(parent: offlinePlaylist, tracks: tracks)
        } else {
            offlinePlaylist = try await create(playlist: playlist, tracks: tracks)
        }
        
        download(parent: offlinePlaylist, tracks: tracks)
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: offlinePlaylist.id)
    }
    
    @MainActor
    func delete(playlistId: String) throws {
        let playlist = try OfflineManager.shared.getOfflinePlaylist(playlistId: playlistId)
        try delete(playlist: playlist)
    }
    
    @MainActor
    func getPlaylist(playlistId: String) throws -> Playlist {
        let playlist = try getOfflinePlaylist(playlistId: playlistId)
        return Playlist.convertFromOffline(playlist)
    }
    
    @MainActor
    func getPlaylists() throws -> [Playlist] {
        try getOfflinePlaylists().map(Playlist.convertFromOffline)
    }
    
    @MainActor
    func getTracks(playlistId: String) throws -> [Track] {
        let playlist = try getOfflinePlaylist(playlistId: playlistId)
        let tracks = try getOfflineTracks(parent: playlist)
        
        return tracks.map { Track.convertFromOffline($0, parent: playlist) }
    }
}
