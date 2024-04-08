//
//  OnlineLibraryDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AFBase
import AFOffline

public struct OnlineLibraryDataProvider: LibraryDataProvider {
    public var supportsArtistLookup: Bool = true
    public var supportsAdvancedFilters: Bool = true
    public var albumNotFoundFallbackToLibrary: Bool = false
    
    public func getRecentAlbums() async throws -> [Album] {
        return try await JellyfinClient.shared.getAlbums(limit: 20, sortOrder: .added, ascending: false, favorite: false)
    }
    public func getRandomAlbums() async throws -> [Album] {
        return try await JellyfinClient.shared.getAlbums(limit: 20)
    }
    
    // MARK: Track
    
    public func getTracks(limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> ([Track], Int) {
        try await JellyfinClient.shared.getTracks(limit: limit, startIndex: startIndex, sortOrder: sortOrder, ascending: ascending, favorite: false)
    }
    public func getFavoriteTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(limit: 0, startIndex: 0, sortOrder: sortOrder, ascending: ascending, favorite: true).0
    }
    
    // MARK: Album
    
    public func getAlbum(albumId: String) async throws -> Album {
        try await JellyfinClient.shared.getAlbum(albumId: albumId)
    }
    public func getAlbums(limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> ([Album], Int) {
        try await JellyfinClient.shared.getAlbums(limit: limit, startIndex: startIndex, sortOrder: sortOrder, ascending: ascending, favorite: false)
    }
    
    public func getTracks(albumId: String) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(albumId: albumId)
    }
    
    // MARK: Artist
    
    public func getArtist(artistId: String) async throws -> Artist {
        try await JellyfinClient.shared.getArtist(artistId: artistId)
    }
    public func getArtists(albumOnly: Bool) async throws -> [Artist] {
        try await JellyfinClient.shared.getArtists(albumOnly: albumOnly)
    }
    
    public func getTracks(artistId: String) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(artistId: artistId).shuffled()
    }
    public func getAlbums(artistId: String, limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> ([Album], Int) {
        try await JellyfinClient.shared.getAlbums(limit: limit, startIndex: startIndex, artistId: artistId, sortOrder: sortOrder, ascending: ascending)
    }
    
    // MARK: Search
    
    public func searchTracks(query: String) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(query: query)
    }
    public func searchAlbums(query: String) async throws -> [Album] {
        try await JellyfinClient.shared.getAlbums(query: query)
    }
    public func searchArtists(query: String) async throws -> [Artist] {
        try await JellyfinClient.shared.getArtists(query: query)
    }
    public func searchPlaylists(query: String) async throws -> [Playlist] {
        try await JellyfinClient.shared.getPlaylists(query: query)
    }
    
    // MARK: Playlist
    
    public func getPlaylists() async throws -> [Playlist] {
        try await JellyfinClient.shared.getPlaylists(limit: 0, sortOrder: .added, ascending: false, favorite: false)
    }
    public func getTracks(playlistId: String) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(playlistId: playlistId)
    }
}
