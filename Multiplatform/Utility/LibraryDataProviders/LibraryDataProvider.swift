//
//  LibraryItemDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import SwiftUI
import AFBase

public protocol LibraryDataProvider {
    var supportsArtistLookup: Bool { get }
    var supportsAdvancedFilters: Bool { get }
    var albumNotFoundFallbackToLibrary: Bool { get }
    
    func getRecentAlbums() async throws -> [Album]
    func getRandomAlbums() async throws -> [Album]
    
    // MARK: Track
    
    func getTracks(limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool, search: String?) async throws -> ([Track], Int)
    func getFavoriteTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track]
    
    // MARK: Album
    
    func getAlbum(albumId: String) async throws -> Album
    func getAlbums(limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool, search: String?) async throws -> ([Album], Int)
    
    func getTracks(albumId: String) async throws -> [Track]
    
    // MARK: Artist
    
    func getArtist(artistId: String) async throws -> Artist
    func getArtists(albumOnly: Bool) async throws -> [Artist]
    
    func getTracks(artistId: String) async throws -> [Track]
    func getAlbums(artistId: String, limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> ([Album], Int)
    
    // MARK: Search
    
    func searchTracks(query: String) async throws -> [Track]
    func searchAlbums(query: String) async throws -> [Album]
    func searchArtists(query: String) async throws -> [Artist]
    func searchPlaylists(query: String) async throws -> [Playlist]
    
    // MARK: Playlist
    
    func getPlaylist(playlistId: String) async throws -> Playlist
    func getPlaylists() async throws -> [Playlist]
    func getTracks(playlistId: String) async throws -> [Track]
}

// MARK: Environment

struct LibraryDataProviderDefault: EnvironmentKey {
    static var defaultValue: LibraryDataProvider = MockLibraryDataProvider()
}
struct LibraryOnlineProviderDefault: EnvironmentKey {
    static var defaultValue: Bool = true
}

public extension EnvironmentValues {
    var libraryDataProvider: LibraryDataProvider {
        get { self[LibraryDataProviderDefault.self] }
        set { self[LibraryDataProviderDefault.self] = newValue }
    }
    var libraryOnline: Bool {
        get { self[LibraryOnlineProviderDefault.self] }
        set { self[LibraryOnlineProviderDefault.self] = newValue }
    }
}
