//
//  OfflineManager+Favorites.swift
//
//
//  Created by Rasmus Krämer on 19.11.23.
//

import Foundation
import SwiftData
import AFBaseKit

public extension OfflineManager {
    @MainActor
    func cacheFavorite(itemId: String, favorite: Bool) {
        if let existing = try? PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineFavorite>(predicate: #Predicate { $0.itemId == itemId })).first {
            existing.favorite = favorite
        } else {
            let offlineFavorite = OfflineFavorite(itemId: itemId, favorite: favorite)
            PersistenceManager.shared.modelContainer.mainContext.insert(offlineFavorite)
        }
    }
    
    @MainActor
    func updateOfflineFavorite(itemId: String, favorite: Bool) {
        if let offlineTrack = try? OfflineManager.shared.getOfflineTrack(trackId: itemId) {
            offlineTrack.favorite = favorite
        } else if let offlineAlbum = try? OfflineManager.shared.getOfflineAlbum(albumId: itemId) {
            offlineAlbum.favorite = favorite
        } else if let offlinePlaylist = try? OfflineManager.shared.getOfflinePlaylist(playlistId: itemId) {
            offlinePlaylist.favorite = favorite
        }
    }
    
    func updateOfflineFavorites() {
        Task.detached {
            do {
                // MARK: sync
                let descriptor = FetchDescriptor<OfflineFavorite>()
                Task { @MainActor in
                    let favorites = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
                    
                    for favorite in favorites {
                        Task.detached {
                            do {
                                try await JellyfinClient.shared.setFavorite(itemId: favorite.itemId, favorite: favorite.favorite)
                                
                                Task { @MainActor in
                                    PersistenceManager.shared.modelContainer.mainContext.delete(favorite)
                                }
                            } catch {
                                Self.logger.fault("Failed to sync offline favorite to server \(favorite.itemId) (\(favorite.favorite))")
                            }
                        }
                    }
                }
                
                // MARK: tracks
                let trackFavorites = try await JellyfinClient.shared.getTracks(limit: 0, sortOrder: .added, ascending: true, favorite: true)
                
                if !trackFavorites.isEmpty {
                    for track in trackFavorites {
                        if let offline = try? await OfflineManager.shared.getOfflineTrack(trackId: track.id), track.favorite != offline.favorite {
                            offline.favorite = track.favorite
                        }
                    }
                    
                    let identifiers = trackFavorites.map { $0.id }
                    
                    Task { @MainActor in
                        let descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { !identifiers.contains($0.id) && $0.favorite == true })
                        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
                        
                        for track in tracks {
                            track.favorite = false
                        }
                    }
                }
                
                // MARK: albums
                let albumFavorites = try await JellyfinClient.shared.getAlbums(limit: 0, sortOrder: .added, ascending: true, favorite: true)
                
                if !albumFavorites.isEmpty {
                    for album in albumFavorites {
                        if let offline = try? await OfflineManager.shared.getOfflineAlbum(albumId: album.id), album.favorite != offline.favorite {
                            offline.favorite = album.favorite
                        }
                    }
                    
                    let identifiers = albumFavorites.map { $0.id }
                    
                    Task { @MainActor in
                        let descriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate { !identifiers.contains($0.id) && $0.favorite == true })
                        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
                        
                        for album in albums {
                            album.favorite = false
                        }
                    }
                }
                
                // MARK: Playlists
                let playlistFavorites = try await JellyfinClient.shared.getPlaylists(limit: 0, sortOrder: .added, ascending: true, favorite: true)
                
                if !playlistFavorites.isEmpty {
                    for playlist in playlistFavorites {
                        if let offline = try? await OfflineManager.shared.getOfflinePlaylist(playlistId: playlist.id), playlist.favorite != offline.favorite {
                            offline.favorite = playlist.favorite
                        }
                    }
                    
                    let identifiers = playlistFavorites.map { $0.id }
                    
                    Task { @MainActor in
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
