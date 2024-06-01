//
//  LibraryItemDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import SwiftUI
import AmpFinKit

public protocol LibraryDataProvider {
    var supportsArtistLookup: Bool { get }
    var supportsAdvancedFilters: Bool { get }
    var albumNotFoundFallbackToLibrary: Bool { get }
    
    // MARK: Tracks
    
    func tracks(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, favoriteOnly: Bool, search: String?) async throws -> ([Track], Int)
    
    // MARK: Albums
    
    func recentAlbums() async throws -> [Album]
    func randomAlbums() async throws -> [Album]
    
    func album(identifier: String) async throws -> Album
    func albums(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, search: String?) async throws -> ([Album], Int)
    
    func tracks(albumId: String) async throws -> [Track]
    
    // MARK: Artists
    
    func artist(identifier: String) async throws -> Artist
    func artists(limit: Int, startIndex: Int, albumOnly: Bool, search: String?) async throws -> ([Artist], Int)
    
    func tracks(artistId: String, sortOrder: ItemSortOrder, ascending: Bool) async throws -> [Track]
    func albums(artistId: String, limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool) async throws -> ([Album], Int)
    
    // MARK: Playlists
    
    func playlist(identifier: String) async throws -> Playlist
    func playlists(search: String?) async throws -> [Playlist]
    func tracks(playlistId: String) async throws -> [Track]
}

// MARK: Environment

struct LibraryDataProviderDefault: EnvironmentKey {
    static var defaultValue: LibraryDataProvider = MockLibraryDataProvider()
}

public extension EnvironmentValues {
    var libraryDataProvider: LibraryDataProvider {
        get { self[LibraryDataProviderDefault.self] }
        set { self[LibraryDataProviderDefault.self] = newValue }
    }
}
