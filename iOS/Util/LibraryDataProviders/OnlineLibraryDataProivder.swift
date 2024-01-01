//
//  OnlineLibraryDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AFBaseKit
import AFOfflineKit

public struct OnlineLibraryDataProvider: LibraryDataProvider {
    public var supportsArtistLookup: Bool = true
    public var supportsFavoritesLookup: Bool = true
    public var supportsAdvancedFilters: Bool = true
    
    public func getAllTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(limit: 0, sortOrder: sortOrder, ascending: ascending, favorite: false)
    }
    public func getFavoriteTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(limit: 0, sortOrder: sortOrder, ascending: ascending, favorite: true)
    }
    
    public func getRecentAlbums() async throws -> [Album] {
        return try await JellyfinClient.shared.getAlbums(limit: 20, sortOrder: .added, ascending: false, favorite: false)
    }
    public func getRecommendedAlbums() async throws -> [Album] {
        return try await JellyfinClient.shared.getAlbums(limit: 20)
    }
    
    public func getAlbumTracks(id: String) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(albumId: id)
    }
    public func getAlbumById(_ albumId: String) async -> Album? {
        await JellyfinClient.shared.getAlbum(albumId: albumId)
    }
    public func getAlbums(limit: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
        try await JellyfinClient.shared.getAlbums(limit: limit, sortOrder: sortOrder, ascending: ascending, favorite: false)
    }
    
    
    public func getArtists(albumOnly: Bool) async throws -> [Artist] {
        try await JellyfinClient.shared.getArtists(albumOnly: albumOnly)
    }
    public func getArtistById(_ artistId: String) async -> Artist? {
        await JellyfinClient.shared.getArtist(artistId: artistId)
    }
    public func getArtistAlbums(id: String, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
        try await JellyfinClient.shared.getAlbums(artistId: id, sortOrder: sortOrder, ascending: ascending)
    }
    
    public func searchTracks(query: String) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(query: query)
    }
    public func searchAlbums(query: String) async throws -> [Album] {
        try await JellyfinClient.shared.getAlbums(query: query)
    }
    
    public func getPlaylists() async throws -> [Playlist] {
        try await JellyfinClient.shared.getPlaylists(limit: 0, sortOrder: .added, ascending: false, favorite: false)
    }
    public func getPlaylistTracks(playlistId: String) async throws -> [Track] {
        try await JellyfinClient.shared.getTracks(playlistId: playlistId)
    }
}
