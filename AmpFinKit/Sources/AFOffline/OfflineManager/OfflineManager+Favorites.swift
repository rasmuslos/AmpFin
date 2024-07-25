//
//  OfflineManager+Favorites.swift
//
//
//  Created by Rasmus Krämer on 19.11.23.
//

import Foundation
import SwiftData
import AFFoundation
import AFNetwork

// MARK: Internal (Higher Order)

internal extension OfflineManager {
    func syncLocalFavorites() async throws {
        let favorites = try await MainActor.run(resultType: [OfflineFavorite].self) {
            try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineFavorite>())
        }
        
        for favorite in favorites {
            try await JellyfinClient.shared.favorite(favorite.value, identifier: favorite.itemIdentifier)
            
            let context = ModelContext(PersistenceManager.shared.modelContainer)
            
            context.delete(favorite)
            try context.save()
        }
    }
    
    func updateTrackFavorites() async throws {
        let trackFavorites = try await JellyfinClient.shared.tracks(limit: 0, startIndex: 0, sortOrder: .added, ascending: true, favoriteOnly: true).0
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if !trackFavorites.isEmpty {
            for track in trackFavorites {
                if let offline = try? offlineTrack(trackId: track.id, context: context), track._favorite != offline.favorite {
                    offline.favorite = track._favorite
                }
            }
        }
        
        let identifiers = trackFavorites.map { $0.id }
        
        let descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { !identifiers.contains($0.id) && $0.favorite == true })
        let tracks = try context.fetch(descriptor)
        
        for track in tracks {
            track.favorite = false
        }
        
        try context.save()
    }
    
    func updateAlbumFavorites() async throws {
        let albumFavorites = try await JellyfinClient.shared.albums(limit: 0, startIndex: 0, sortOrder: .added, ascending: true, favoriteOnly: true).0
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if !albumFavorites.isEmpty {
            for album in albumFavorites {
                if let offline = try? offlineAlbum(albumId: album.id, context: context), album._favorite != offline.favorite {
                    offline.favorite = album._favorite
                }
            }
            
            let identifiers = albumFavorites.map { $0.id }
            
            let descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate { !identifiers.contains($0.id) && $0.favorite == true })
            let albums = try context.fetch(descriptor)
            
            for album in albums {
                album.favorite = false
            }
            
            try context.save()
        }
    }
    
    func updatePlaylistFavorites() async throws {
        let playlistFavorites = try await JellyfinClient.shared.playlists(limit: 0, sortOrder: .added, ascending: true, favoriteOnly: true)
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if !playlistFavorites.isEmpty {
            for playlist in playlistFavorites {
                if let offline = try? offlinePlaylist(playlistId: playlist.id, context: context), playlist._favorite != offline.favorite {
                    offline.favorite = playlist._favorite
                }
            }
            
            let identifiers = playlistFavorites.map { $0.id }
            
            let descriptor = FetchDescriptor<OfflinePlaylist>(predicate: #Predicate { !identifiers.contains($0.id) && $0.favorite == true })
            let playlists = try context.fetch(descriptor)
            
            for playlist in playlists {
                playlist.favorite = false
            }
            
            try context.save()
        }
    }
}

// MARK: Public (Higher Order)

public extension OfflineManager {
    func cache(favorite: Bool, itemId: String) {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if let existing = try? context.fetch(FetchDescriptor<OfflineFavorite>(predicate: #Predicate { $0.itemIdentifier == itemId })).first {
            existing.value = favorite
        } else {
            let offlineFavorite = OfflineFavorite(itemIdentifier: itemId, value: favorite)
            
            context.insert(offlineFavorite)
            try? context.save()
        }
    }
    
    func update(favorite: Bool, itemId: String) {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if let offlineTrack = try? offlineTrack(trackId: itemId, context: context) {
            offlineTrack.favorite = favorite
        } else if let offlineAlbum = try? offlineAlbum(albumId: itemId, context: context) {
            offlineAlbum.favorite = favorite
        } else if let offlinePlaylist = try? offlinePlaylist(playlistId: itemId, context: context) {
            offlinePlaylist.favorite = favorite
        }
    }
}
