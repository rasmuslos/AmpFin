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
    func create(itemId: String, favorite: Bool) {
        let offlineFavorite = OfflineFavorite(itemId: itemId, favorite: favorite)
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineFavorite)
    }
    
    @MainActor
    func updateOfflineFavorite(itemId: String, favorite: Bool) {
        if let offlineTrack = OfflineManager.shared.getOfflineTrack(trackId: itemId) {
            offlineTrack.favorite = favorite
        } else if let offlineAlbum = OfflineManager.shared.getOfflineAlbum(albumId: itemId) {
            offlineAlbum.favorite = favorite
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
                            try await JellyfinClient.shared.setFavorite(itemId: favorite.itemId, favorite: favorite.favorite)
                            
                            Task { @MainActor in
                                PersistenceManager.shared.modelContainer.mainContext.delete(favorite)
                            }
                        }
                    }
                }
                
                // MARK: tracks
                let trackFavorites = try await JellyfinClient.shared.getTracks(limit: 0, sortOrder: .added, ascending: true, favorite: true)
                
                if !trackFavorites.isEmpty {
                    for track in trackFavorites {
                        if let offline = await OfflineManager.shared.getOfflineTrack(trackId: track.id), track.favorite != offline.favorite {
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
                        if let offline = await OfflineManager.shared.getOfflineAlbum(albumId: album.id), album.favorite != offline.favorite {
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
            } catch {
                Self.logger.fault("Failed to sync favorites")
                print(error)
            }
        }
    }
}
