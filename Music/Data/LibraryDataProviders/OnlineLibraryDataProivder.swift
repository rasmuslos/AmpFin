//
//  OnlineLibraryDataProivder.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

struct OnlineLibraryDataProivder: LibraryDataProvider {
    func getAllTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track] {
        try await JellyfinClient.shared.getAllTracks(sortOrder: sortOrder, ascending: ascending)
    }
    
    func getRecentAlbums() async throws -> [Album] {
        try await JellyfinClient.shared.getAlbums(limit: 20, sortOrder: .added, ascending: false)
    }
    func getAlbumTracks(id: String) async throws -> [Track] {
        try await JellyfinClient.shared.getAlbumTracks(id: id)
    }
    func getAlbums(limit: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
        try await JellyfinClient.shared.getAlbums(limit: limit, sortOrder: sortOrder, ascending: ascending)
    }
    
    
    func getArtists(albumOnly: Bool) async throws -> [Artist] {
        try await JellyfinClient.shared.getArtists(albumOnly: albumOnly)
    }
    func getArtistAlbums(id: String, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album] {
        try await JellyfinClient.shared.getArtistAlbums(id: id, sortOrder: sortOrder, ascending: ascending)
    }
    func getArtistById(_ artistId: String) async throws -> Artist? {
        try await JellyfinClient.shared.getArtistById(artistId)
    }
}
