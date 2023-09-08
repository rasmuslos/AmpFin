//
//  OfflineLibraryDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import Foundation

struct OfflineLibraryDataProvider: LibraryDataProvider {
    func getAllTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
        let tracks = try await OfflineManager.shared.getAllTracks().sorted {
            switch sortOrder {
            case .name:
                return $0.name < $1.name
            case .album:
                return $0.album.name < $1.album.name
            case .albumArtist:
                return $0.album.artists.first?.name ?? "?" < $1.album.artists.first?.name ?? "?"
            case .artist:
                return $0.artists.first?.name ?? "?" < $1.artists.first?.name ?? "?"
            case .added, .released:
                return $0.releaseDate ?? Date(timeIntervalSince1970: 0) < $1.releaseDate ?? Date(timeIntervalSince1970: 0)
            case .plays, .runtime:
                return false
            }
        }
        
        return ascending ? tracks : tracks.reversed()
    }
    
    func getRecentAlbums() async throws -> [Album] {
        try await OfflineManager.shared.getRecentAlbums()
    }
    
    func getAlbumTracks(id: String) async throws -> [Track] {
        if let album = try await OfflineManager.shared.getOfflineAlbum(albumId: id) {
            return try await OfflineManager.shared.getAlbumTracks(album).map(Track.convertFromOffline)
        }
        
        throw JellyfinClientError.invalidResponse
    }
    
    func getAlbums(limit: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
        let albums = try await OfflineManager.shared.getAllAlbums().sorted {
            switch sortOrder {
            case .name, .album:
                return $0.name < $1.name
            case .albumArtist, .artist:
                return $0.artists.first?.name ?? "?" < $1.artists.first?.name ?? "?"
            case .added, .released:
                return $0.releaseDate ?? Date(timeIntervalSince1970: 0) < $1.releaseDate ?? Date(timeIntervalSince1970: 0)
            case .plays, .runtime:
                return false
            }
        }

        return ascending ? albums : albums.reversed()
    }
    
    func getArtists(albumOnly: Bool) async throws -> [Artist] {
        return []
    }
    
    func getArtistAlbums(id: String, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
        return []
    }
    
    
}
