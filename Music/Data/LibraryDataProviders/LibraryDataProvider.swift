//
//  LibraryItemDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import SwiftUI

protocol LibraryDataProvider {
    func getAllTracks(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Track]
    
    func getRecentAlbums() async throws -> [Album]
    func getAlbumTracks(id: String) async throws -> [Track]
    func getAlbums(limit: Int, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album]
    
    func getArtists(albumOnly: Bool) async throws -> [Artist]
    func getArtistAlbums(id: String, sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [Album]
    
    func getArtistById(_ artistId: String) async throws -> Artist?
}

struct LibraryDataProviderDefault: EnvironmentKey {
    static var defaultValue: LibraryDataProvider = OnlineLibraryDataProivder()
}
struct LibraryOnlineProviderDefault: EnvironmentKey {
    static var defaultValue: Bool = true
}

extension EnvironmentValues {
    var libraryDataProvider: LibraryDataProvider {
        get { self[LibraryDataProviderDefault.self] }
        set { self[LibraryDataProviderDefault.self] = newValue }
    }
    var libraryOnline: Bool {
        get { self[LibraryOnlineProviderDefault.self] }
        set { self[LibraryOnlineProviderDefault.self] = newValue }
    }
}
