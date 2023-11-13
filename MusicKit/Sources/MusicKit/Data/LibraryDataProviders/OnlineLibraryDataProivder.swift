//
//  OnlineLibraryDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

public struct OnlineLibraryDataProvider: LibraryDataProvider {
    public var supportsArtistLookup: Bool = true
    public var supportsFavoritesLookup: Bool = true
    public var supportsAdvancedFilters: Bool = true
    
    public func getAllTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
        try await JellyfinClient.shared.getAllTracks(sortOrder: sortOrder, ascending: ascending)
    }
    public func getFavoriteTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
        try await JellyfinClient.shared.getFavoriteTracks(sortOrder: sortOrder, ascending: ascending)
    }
    
    public func getRecentAlbums() async throws -> [Album] {
        // this is a great place to sync playbacks (async)
        PlaybackReporter.syncPlaysToJellyfinServer()
        
        return try await JellyfinClient.shared.getAlbums(limit: 20, sortOrder: .added, ascending: false)
    }
    public func getAlbumTracks(id: String) async throws -> [Track] {
        try await JellyfinClient.shared.getAlbumTracks(id: id)
    }
    public func getAlbumById(_ albumId: String) async throws -> Album? {
        try await JellyfinClient.shared.getAlbumById(albumId)
    }
    public func getAlbums(limit: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
        try await JellyfinClient.shared.getAlbums(limit: limit, sortOrder: sortOrder, ascending: ascending)
    }
    
    
    public func getArtists(albumOnly: Bool) async throws -> [Artist] {
        try await JellyfinClient.shared.getArtists(albumOnly: albumOnly)
    }
    public func getArtistById(_ artistId: String) async throws -> Artist? {
        try await JellyfinClient.shared.getArtistById(artistId)
    }
    public func getArtistAlbums(id: String, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
        try await JellyfinClient.shared.getArtistAlbums(artistId: id, sortOrder: sortOrder, ascending: ascending)
    }
    
    public func searchTracks(query: String) async throws -> [Track] {
        try await JellyfinClient.shared.searchTracks(query: query)
    }
    public func searchAlbums(query: String) async throws -> [Album] {
        try await JellyfinClient.shared.searchAlbums(query: query)
    }
    
    public init() {
    }
}
