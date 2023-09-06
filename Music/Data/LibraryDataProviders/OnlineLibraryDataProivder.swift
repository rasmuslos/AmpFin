//
//  OnlineLibraryDataProivder.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

struct OnlineLibraryDataProivder: LibraryDataProvider {
    func getAllSongs(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [SongItem] {
        try await JellyfinClient.shared.getAllSongs(sortOrder: sortOrder, ascending: ascending)
    }
    
    func getRecentAlbums() async throws -> [AlbumItem] {
        try await JellyfinClient.shared.getAlbums(limit: 20, sortOrder: .added, ascending: false)
    }
    func getAlbumItems(id: String) async throws -> [SongItem] {
        try await JellyfinClient.shared.getAlbumItems(id: id)
    }
}
