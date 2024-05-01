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
    public func getRandomAlbums() async throws -> [Album] {
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
    
    // MARK: Track
    
    public func getTracks(limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool, favorite: Bool, search: String?) async throws -> ([Track], Int) {
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
    
    public func getAlbum(albumId: String) async throws -> Album {
        Album.fixture
    }
    public func getAlbums(limit: Int, startIndex: Int, sortOrder: AFBase.JellyfinClient.ItemSortOrder, ascending: Bool, search: String?) async throws -> ([AFBase.Album], Int) {
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
    
    public func getTracks(albumId: String) async throws -> [Track] {
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
    
    public func getArtist(artistId: String) async throws -> Artist {
        Artist.fixture
    }
    public func getArtists(limit: Int, startIndex: Int, albumOnly: Bool, search: String?) async throws -> ([Artist], Int) {
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
    
    public func getTracks(artistId: String, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
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
    public func getAlbums(artistId: String, limit: Int, startIndex: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> ([Album], Int) {
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
    
    // MARK: Search
    
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
    public func searchArtists(query: String) async throws -> [Artist] {
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
    
    // MARK: Playlist
    
    public func getPlaylist(playlistId: String) async throws -> Playlist {
        Playlist.fixture
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
    public func getTracks(playlistId: String) async throws -> [Track] {
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
