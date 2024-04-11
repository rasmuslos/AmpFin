//
//  OfflineLibraryDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import Foundation
import AFBase
import AFOffline

public struct OfflineLibraryDataProvider: LibraryDataProvider {
    public var supportsArtistLookup: Bool = false
    public var supportsAdvancedFilters: Bool = false
    public var albumNotFoundFallbackToLibrary: Bool = true
    
    public func getRecentAlbums() async throws -> [Album] {
        try await OfflineManager.shared.getRecentAlbums()
    }
    public func getRandomAlbums() async throws -> [Album] {
        try await OfflineManager.shared.getRandomAlbums()
    }
    
    // MARK: Track
    
    public func getTracks(limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool, search: String?) async throws -> ([Track], Int) {
        var tracks = try await OfflineManager.shared.getTracks().sorted {
            switch sortOrder {
                case .name:
                    return $0.name < $1.name
                case .album:
                    return $0.album.name ?? "?" < $1.album.name ?? "?"
                case .albumArtist:
                    return $0.album.artists.first?.name ?? "?" < $1.album.artists.first?.name ?? "?"
                case .artist:
                    return $0.artists.first?.name ?? "?" < $1.artists.first?.name ?? "?"
                case .added, .released:
                    return $0.releaseDate ?? Date(timeIntervalSince1970: 0) < $1.releaseDate ?? Date(timeIntervalSince1970: 0)
                case .plays, .runtime, .lastPlayed:
                    return false
            }
        }
        
        if ascending {
            tracks.reverse()
        }
        
        if let search = search {
            tracks = tracks.filter {
                $0.name.localizedStandardContains(search)
                || $0.artists.map { $0.name }.reduce(false, { $0 || $1.localizedStandardContains(search) })
            }
        }
        
        return (tracks, tracks.count)
    }
    public func getFavoriteTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
        try await OfflineManager.shared.getTracks(favorite: true)
    }
    
    // MARK: Album
    
    public func getAlbum(albumId: String) async throws -> Album {
        try await OfflineManager.shared.getAlbum(albumId: albumId)
    }
    public func getAlbums(limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool, search: String?) async throws -> ([Album], Int) {
        var albums = try await OfflineManager.shared.getAlbums().sorted {
            switch sortOrder {
                case .name, .album:
                    return $0.name < $1.name
                case .albumArtist, .artist:
                    return $0.artists.first?.name ?? "?" < $1.artists.first?.name ?? "?"
                case .added, .released:
                    return $0.releaseDate ?? Date(timeIntervalSince1970: 0) < $1.releaseDate ?? Date(timeIntervalSince1970: 0)
                case .plays, .runtime, .lastPlayed:
                    return false
            }
        }
        
        if ascending {
            albums.reverse()
        }
        
        
        if let search = search {
            albums = albums.filter {
                $0.name.localizedStandardContains(search)
                || $0.artists.map { $0.name }.reduce(false, { $0 || $1.localizedStandardContains(search) })
            }
        }
        
        return (albums, albums.count)
    }
    
    public func getTracks(albumId: String) async throws -> [Track] {
        return try await OfflineManager.shared.getTracks(albumId: albumId)
    }
    
    // MARK: Artist
    
    public func getArtist(artistId: String) async throws -> Artist {
        throw JellyfinClientError.invalidResponse
    }
    public func getArtists(limit: Int, startIndex: Int, albumOnly: Bool, search: String?) async throws -> ([Artist], Int) {
        throw JellyfinClientError.invalidResponse
    }
    
    public func getTracks(artistId: String) async throws -> [Track] {
        try await OfflineManager.shared.getTracks(artistId: artistId).shuffled()
    }
    public func getAlbums(artistId: String, limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> ([Album], Int) {
        throw JellyfinClientError.invalidResponse
    }
    
    // MARK: Search
    
    public func searchTracks(query: String) async throws -> [Track] {
        try await OfflineManager.shared.getTracks(query: query)
    }
    public func searchAlbums(query: String) async throws -> [Album] {
        try await OfflineManager.shared.getAlbums(query: query)
    }
    public func searchArtists(query: String) async throws -> [Artist] {
        []
    }
    public func searchPlaylists(query: String) async throws -> [Playlist] {
        try await OfflineManager.shared.getPlaylists(query: query)
    }
    
    // MARK: Playlist
    
    public func getPlaylist(playlistId: String) async throws -> Playlist {
        try await OfflineManager.shared.getPlaylist(playlistId: playlistId)
    }
    public func getPlaylists() async throws -> [Playlist] {
        try await OfflineManager.shared.getPlaylists()
    }
    public func getTracks(playlistId: String) async throws -> [Track] {
        try await OfflineManager.shared.getTracks(playlistId: playlistId)
    }
}
