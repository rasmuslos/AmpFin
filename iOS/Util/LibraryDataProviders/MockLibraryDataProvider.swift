//
//  MockLibraryDataProvider.swift
//
//
//  Created by Rasmus Krämer on 14.11.23.
//

import Foundation
import AFBase

public struct MockLibraryDataProvider: LibraryDataProvider {
    public var supportsArtistLookup: Bool = true
    public var supportsAdvancedFilters: Bool = true
    public var albumNotFoundFallbackToLibrary: Bool = false
    
    public func getAllTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
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
    
    public func getFavoriteTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
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
    
    public func getRecentAlbums() async throws -> [Album] {
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
    public func getRecommendedAlbums() async throws -> [Album] {
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
    
    public func getAlbumTracks(id: String) async throws -> [Track] {
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
    
    public func getAlbumById(_ albumId: String) async throws -> Album {
        Album.fixture
    }
    
    public func getAlbums(limit: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
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
    
    public func getArtists(albumOnly: Bool) async throws -> [Artist] {
        [
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
        ]
    }
    
    public func getArtistById(_ artistId: String) async throws -> Artist {
        Artist.fixture
    }
    
    public func getArtistAlbums(id: String, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
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
    public func getArtistTracks(id: String) async throws -> [Track] {
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
    
    public func searchTracks(query: String) async throws -> [Track] {
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
    
    public func searchAlbums(query: String) async throws -> [Album] {
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
    
    public func searchPlaylists(query: String) async throws -> [Playlist] {
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
    
    public func getPlaylists() async throws -> [Playlist] {
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
    public func getPlaylistTracks(playlistId: String) async throws -> [Track] {
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
