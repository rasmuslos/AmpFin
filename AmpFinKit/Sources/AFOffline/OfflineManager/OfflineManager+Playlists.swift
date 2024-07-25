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

// MARK: Internal (Helper)

internal extension OfflineManager {
    func create(playlist: Playlist, tracks: [Track], context: ModelContext) throws -> OfflinePlaylist {
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
        
        context.insert(offlinePlaylist)
        try context.save()
        
        return offlinePlaylist
    }
    
    func delete(playlist: OfflinePlaylist, context: ModelContext) throws {
        context.delete(playlist)
        try context.save()
        
        try DownloadManager.shared.deleteCover(parentId: playlist.id)
        try removeOrphans(context: context)
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: playlist.id)
    }
    
    func offlinePlaylist(playlistId identifier: String, context: ModelContext) throws -> OfflinePlaylist {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflinePlaylist> { $0.id == identifier })
        descriptor.fetchLimit = 1
        
        guard let playlist = try context.fetch(descriptor).first else {
            throw OfflineError.notFound
        }
        
        return playlist
    }
    
    func offlinePlaylists(context: ModelContext) throws -> [OfflinePlaylist] {
        try context.fetch(FetchDescriptor())
    }
}

// MARK: Public (Higher Order)

public extension OfflineManager {
    func download(playlist: Playlist) async throws {
        let tracks = try await JellyfinClient.shared.tracks(playlistId: playlist.id)
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let offlinePlaylist: OfflinePlaylist
        
        if let existing = try? self.offlinePlaylist(playlistId: playlist.id, context: context) {
            offlinePlaylist = existing
            offlinePlaylist.childrenIdentifiers = tracks.map { $0.id }
        } else {
            offlinePlaylist = try create(playlist: playlist, tracks: tracks, context: context)
        }
        
        for track in tracks {
            download(track: track, context: context)
        }
        
        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: offlinePlaylist.id)
    }
    
    func delete(playlistId identifier: String) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let playlist = try OfflineManager.shared.offlinePlaylist(playlistId: identifier, context: context)
        
        try delete(playlist: playlist, context: context)
    }
    
    func playlist(playlistId identifier: String) throws -> Playlist {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let playlist = try offlinePlaylist(playlistId: identifier, context: context)
        
        return Playlist(playlist)
    }
    
    func playlists() throws -> [Playlist] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let playlists = try offlinePlaylists(context: context)
            
        return playlists.map(Playlist.init)
    }
    
    func tracks(playlistId identifier: String) throws -> [Track] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        let playlist = try offlinePlaylist(playlistId: identifier, context: context)
        let tracks = try offlineTracks(parent: playlist, context: context)
        
        return tracks.map { Track($0, parent: playlist) }
    }
    
    func offlineStatus(playlistId identifier: String) -> ItemOfflineTracker.OfflineStatus {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        do {
            let playlist = try offlinePlaylist(playlistId: identifier, context: context)
            let inProgress = try downloadInProgress(parent: playlist, context: context)
            
            return inProgress ? .working : .downloaded
        } catch {
            return .none
        }
    }
}
