//
//  OfflineLibraryDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import Foundation
import AmpFinKit

public struct OfflineLibraryDataProvider: LibraryDataProvider {
    public var supportsArtistLookup: Bool = false
    public var supportsAdvancedFilters: Bool = false
    public var albumNotFoundFallbackToLibrary: Bool = true
    
    // MARK: Track
    
    public func tracks(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, favoriteOnly: Bool, search: String?) async throws -> ([Track], Int) {
        var tracks: [Track]
        let count: Int
        
        if let search = search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tracks = try OfflineManager.shared.tracks(search: search)
            count = tracks.count
        } else {
            tracks = try OfflineManager.shared.tracks(favoriteOnly: favoriteOnly, limit: limit, offset: startIndex)
            count = try OfflineManager.shared.trackCount()
        }
        
        tracks = filterSort(tracks: tracks, sortOrder: sortOrder, ascending: ascending)
        return (tracks, count)
    }
    
    // MARK: Album
    
    public func recentAlbums() async throws -> [Album] {
        try OfflineManager.shared.recentAlbums()
    }
    public func randomAlbums() async throws -> [Album] {
        try OfflineManager.shared.randomAlbums()
    }
    
    public func album(identifier: String) async throws -> Album {
        try OfflineManager.shared.album(identifier: identifier)
    }
    public func albums(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, search: String?) async throws -> ([Album], Int) {
        var albums: [Album]
        let count: Int
        
        if let search = search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            albums = try OfflineManager.shared.albums(search: search)
            count = albums.count
        } else {
            albums = try OfflineManager.shared.albums(limit: limit, offset: startIndex)
            count = try OfflineManager.shared.albumCount()
        }
        
        albums = filterSort(albums: albums, sortOrder: sortOrder, ascending: ascending, artistId: nil)
        return (albums, count)
    }
    
    public func tracks(albumId: String) async throws -> [Track] {
        try OfflineManager.shared.tracks(albumId: albumId)
    }
    
    // MARK: Artist
    
    public func artist(identifier: String) async throws -> Artist {
        throw JellyfinClient.ClientError.invalidHttpBody
    }
    public func artists(limit: Int, startIndex: Int, albumOnly: Bool, search: String?) async throws -> ([Artist], Int) {
        ([], 0)
    }
    
    public func tracks(artistId: String, sortOrder: ItemSortOrder, ascending: Bool) async throws -> [Track] {
        var tracks = try OfflineManager.shared.tracks(artistId: artistId)
        tracks = filterSort(tracks: tracks, sortOrder: sortOrder, ascending: ascending)
        
        return tracks
    }
    public func albums(artistId: String, limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool) async throws -> ([Album], Int) {
        throw JellyfinClient.ClientError.unknownMessage
    }
    
    // MARK: Playlist
    
    public func playlist(identifier: String) async throws -> Playlist {
        try OfflineManager.shared.playlist(playlistId: identifier)
    }
    public func playlists(search: String?) async throws -> [Playlist] {
        var playlists = try OfflineManager.shared.playlists()
        
        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            playlists = playlists.filter { $0.name.localizedStandardContains(search) }
        }
        
        return playlists
    }
    public func tracks(playlistId: String) async throws -> [Track] {
        try OfflineManager.shared.tracks(playlistId: playlistId)
    }
}

private extension OfflineLibraryDataProvider {
    func filterSort(tracks: [Track], sortOrder: ItemSortOrder, ascending: Bool) -> [Track] {
        var tracks = tracks
        
        tracks.sort {
            switch sortOrder {
                case .name:
                    return $0.name < $1.name
                case .album:
                    return $0.album.name ?? "?" < $1.album.name ?? "?"
                case .albumArtist:
                    return $0.album.artists.first?.name ?? "?" < $1.album.artists.first?.name ?? "?"
                case .artist:
                    return $0.artists.first?.name ?? "?" < $1.artists.first?.name ?? "?"
                case .released:
                    return $0.releaseDate ?? Date(timeIntervalSince1970: 0) < $1.releaseDate ?? Date(timeIntervalSince1970: 0)
                case .added, .plays, .runtime, .lastPlayed, .random:
                    return false
            }
        }
        
        if sortOrder == .random {
            tracks.shuffle()
        } else if ascending {
            tracks.reverse()
        }
        
        return tracks
    }
    
    func filterSort(albums: [Album], sortOrder: ItemSortOrder, ascending: Bool, artistId: String?) -> [Album] {
        var albums = albums
        
        if let artistId {
            albums = albums.filter { $0.artists.map { $0.id }.contains(artistId) }
        }
        
        albums.sort {
            switch sortOrder {
                case .name, .album:
                    return $0.name < $1.name
                case .albumArtist, .artist:
                    return $0.artists.first?.name ?? "?" < $1.artists.first?.name ?? "?"
                case .added, .released:
                    return $0.releaseDate ?? Date(timeIntervalSince1970: 0) < $1.releaseDate ?? Date(timeIntervalSince1970: 0)
                case .plays, .runtime, .lastPlayed, .random:
                    return false
            }
        }
        
        if sortOrder == .random {
            albums.shuffle()
        } else if ascending {
            albums.reverse()
        }
        
        return albums
    }
}
