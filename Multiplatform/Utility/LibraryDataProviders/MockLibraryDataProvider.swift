//
//  MockLibraryDataProvider.swift
//
//
//  Created by Rasmus Krämer on 14.11.23.
//

import Foundation
import AmpFinKit

public struct MockLibraryDataProvider: LibraryDataProvider {
    public var supportsArtistLookup: Bool = true
    public var supportsAdvancedFilters: Bool = true
    public var albumNotFoundFallbackToLibrary: Bool = false
    
    // MARK: Track
    
    public func tracks(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, favoriteOnly: Bool, search: String?) async throws -> ([Track], Int) {
        ([
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
        ], 7)
    }
    
    // MARK: Album
    
    public func recentAlbums() async throws -> [Album] {
        [
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
        ]
    }
    public func randomAlbums() async throws -> [Album] {
        [
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
        ]
    }
    
    public func album(identifier: String) async throws -> Album {
        Album.fixture
    }
    public func albums(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, search: String?) async throws -> ([Album], Int) {
        ([
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
        ], 7)
    }
    
    public func tracks(albumId: String) async throws -> [Track] {
        [
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
        ]
    }
    
    // MARK: Artist
    
    public func artist(identifier: String) async throws -> Artist {
        Artist.fixture
    }
    public func artists(limit: Int, startIndex: Int, albumOnly: Bool, search: String?) async throws -> ([Artist], Int) {
        ([
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
        ], 7)
    }
    
    public func tracks(artistId: String, sortOrder: ItemSortOrder, ascending: Bool) async throws -> [Track] {
        [
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
        ]
    }
    public func albums(artistId: String, limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool) async throws -> ([Album], Int) {
        ([
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
            Album.fixture,
        ], 7)
    }
    
    // MARK: Playlist
    
    public func playlist(identifier: String) async throws -> Playlist {
        Playlist.fixture
    }
    public func playlists(search: String?) async throws -> [Playlist] {
        [
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
        ]
    }
    public func tracks(playlistId: String) async throws -> [Track] {
        [
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
        ]
    }
}
