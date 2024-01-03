//
//  LibraryItemDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import SwiftUI
import AFBaseKit

public protocol LibraryDataProvider {
    var supportsArtistLookup: Bool { get }
    var supportsAdvancedFilters: Bool { get }
    var albumNotFoundFallbackToLibrary: Bool { get }
    
    func getAllTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track]
    func getFavoriteTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track]
    
    func getRecentAlbums() async throws -> [Album]
    func getRecommendedAlbums() async throws -> [Album]
    
    func getAlbumTracks(id: String) async throws -> [Track]
    func getAlbumById(_ albumId: String) async throws -> Album
    func getAlbums(limit: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album]
    
    func getArtists(albumOnly: Bool) async throws -> [Artist]
    func getArtistById(_ artistId: String) async throws -> Artist
    func getArtistAlbums(id: String, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album]
    
    func searchTracks(query: String) async throws -> [Track]
    func searchAlbums(query: String) async throws -> [Album]
    
    func getPlaylists() async throws -> [Playlist]
    func getPlaylistTracks(playlistId: String) async throws -> [Track]
}

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
