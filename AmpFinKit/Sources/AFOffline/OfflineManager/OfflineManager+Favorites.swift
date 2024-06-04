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

extension OfflineManager {
    func updateFavorites() {
        Task {
            do {
                // MARK: Sync
                
                try await MainActor.run {
                    let descriptor = FetchDescriptor<OfflineFavorite>()
                    let favorites = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
                    
                    Task {
                        for favorite in favorites {
                            try await JellyfinClient.shared.favorite(favorite.value, identifier: favorite.itemIdentifier)
                            
                            await MainActor.run {
                                PersistenceManager.shared.modelContainer.mainContext.delete(favorite)
                            }
                        }
                    }
                }
                
                // MARK: Tracks
                
                let trackFavorites = try await JellyfinClient.shared.tracks(limit: 0, startIndex: 0, sortOrder: .added, ascending: true, favoriteOnly: true).0
                
                try await MainActor.run {
                    if !trackFavorites.isEmpty {
                        for track in trackFavorites {
                            if let offline = try? offlineTrack(trackId: track.id), track._favorite != offline.favorite {
                                offline.favorite = track._favorite
                            }
                        }
                    }
                    
                    let identifiers = trackFavorites.map { $0.id }
                    
                    let descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { !identifiers.contains($0.id) && $0.favorite == true })
                    let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
                    
                    for track in tracks {
                        track.favorite = false
                    }
                }
                
                // MARK: Albums
                
                let albumFavorites = try await JellyfinClient.shared.albums(limit: 0, startIndex: 0, sortOrder: .added, ascending: true, favoriteOnly: true).0
                
                try await MainActor.run {
                    if !albumFavorites.isEmpty {
                        for album in albumFavorites {
                            if let offline = try? offlineAlbum(albumId: album.id), album._favorite != offline.favorite {
                                offline.favorite = album._favorite
                            }
                        }
                        
                        let identifiers = albumFavorites.map { $0.id }
                        
                        let descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate { !identifiers.contains($0.id) && $0.favorite == true })
                        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
                        
                        for album in albums {
                            album.favorite = false
                        }
                    }
                }
                
                // MARK: Playlists
                
                let playlistFavorites = try await JellyfinClient.shared.playlists(limit: 0, sortOrder: .added, ascending: true, favoriteOnly: true)
                
                try await MainActor.run {
                    if !playlistFavorites.isEmpty {
                        for playlist in playlistFavorites {
                            if let offline = try? offlinePlaylist(playlistId: playlist.id), playlist._favorite != offline.favorite {
                                offline.favorite = playlist._favorite
                            }
                        }
                        
                        let identifiers = playlistFavorites.map { $0.id }
                        
                        let descriptor = FetchDescriptor<OfflinePlaylist>(predicate: #Predicate { !identifiers.contains($0.id) && $0.favorite == true })
                        let playlists = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
                        
                        for playlist in playlists {
                            playlist.favorite = false
                        }
                    }
                }
            } catch {
                Self.logger.fault("Failed to sync favorites")
                print(error)
            }
        }
    }
}

public extension OfflineManager {
    @MainActor
    func cache(favorite: Bool, itemId: String) {
        if let existing = try? PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineFavorite>(predicate: #Predicate { $0.itemIdentifier == itemId })).first {
            existing.value = favorite
        } else {
            let offlineFavorite = OfflineFavorite(itemIdentifier: itemId, value: favorite)
            PersistenceManager.shared.modelContainer.mainContext.insert(offlineFavorite)
        }
    }
    
    @MainActor
    func update(favorite: Bool, itemId: String) {
        if let offlineTrack = try? offlineTrack(trackId: itemId) {
            offlineTrack.favorite = favorite
        } else if let offlineAlbum = try? offlineAlbum(albumId: itemId) {
            offlineAlbum.favorite = favorite
        } else if let offlinePlaylist = try? offlinePlaylist(playlistId: itemId) {
            offlinePlaylist.favorite = favorite
        }
    }
}
