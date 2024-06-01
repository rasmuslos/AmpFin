//
//  OnlineLibraryDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AmpFinKit

public struct OnlineLibraryDataProvider: LibraryDataProvider {
    public var supportsArtistLookup: Bool = true
    public var supportsAdvancedFilters: Bool = true
    public var albumNotFoundFallbackToLibrary: Bool = false
    
    // MARK: Track
    
    public func tracks(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, favoriteOnly: Bool, search: String?) async throws -> ([Track], Int) {
        try await JellyfinClient.shared.tracks(limit: limit, startIndex: startIndex, sortOrder: sortOrder, ascending: ascending, favoriteOnly: favoriteOnly, search: search)
    }
    
    // MARK: Album
    
    public func recentAlbums() async throws -> [Album] {
        return try await JellyfinClient.shared.albums(limit: 20, startIndex: 0, sortOrder: .added, ascending: false).0
    }
    public func randomAlbums() async throws -> [Album] {
        return try await JellyfinClient.shared.albums(limit: 20, startIndex: 0, sortOrder: .random, ascending: true).0
    }
    
    public func album(identifier: String) async throws -> Album {
        try await JellyfinClient.shared.album(identifier: identifier)
    }
    public func albums(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, search: String?) async throws -> ([Album], Int) {
        try await JellyfinClient.shared.albums(limit: limit, startIndex: startIndex, sortOrder: sortOrder, ascending: ascending, search: search)
    }
    
    public func tracks(albumId: String) async throws -> [Track] {
        try await JellyfinClient.shared.tracks(albumId: albumId)
    }
    
    // MARK: Artist
    
    public func artist(identifier: String) async throws -> Artist {
        try await JellyfinClient.shared.artist(identifier: identifier)
    }
    public func artists(limit: Int, startIndex: Int, albumOnly: Bool, search: String?) async throws -> ([Artist], Int) {
        try await JellyfinClient.shared.artists(limit: limit, startIndex: startIndex, albumOnly: albumOnly, search: search)
    }
    
    public func tracks(artistId: String, sortOrder: ItemSortOrder, ascending: Bool) async throws -> [Track] {
        try await JellyfinClient.shared.tracks(artistId: artistId, sortOrder: sortOrder, ascending: ascending)
    }
    public func albums(artistId: String, limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool) async throws -> ([Album], Int) {
        try await JellyfinClient.shared.albums(limit: limit, startIndex: startIndex, sortOrder: sortOrder, ascending: ascending, artistId: artistId)
    }
    
    // MARK: Playlists
    
    public func playlist(identifier: String) async throws -> Playlist {
        try await JellyfinClient.shared.playlist(identifier: identifier)
    }
    public func playlists(search: String?) async throws -> [Playlist] {
        try await JellyfinClient.shared.playlists(limit: 0, sortOrder: .lastPlayed, ascending: false, search: search)
    }
    public func tracks(playlistId: String) async throws -> [Track] {
        try await JellyfinClient.shared.tracks(playlistId: playlistId)
    }
}
