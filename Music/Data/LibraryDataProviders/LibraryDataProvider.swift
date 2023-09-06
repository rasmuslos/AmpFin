//
//  LibraryItemDataProvider.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import SwiftUI

protocol LibraryDataProvider {
    func getAllSongs(sortOrder: JellyfinClient.ItemSortOrder, ascending: Bool) async throws -> [SongItem]
    
    func getRecentAlbums() async throws -> [AlbumItem]
    func getAlbumItems(id: String) async throws -> [SongItem]
}

struct LibraryDataProviderDefault: EnvironmentKey {
    static var defaultValue: LibraryDataProvider = OnlineLibraryDataProivder()
}

extension EnvironmentValues {
    var libraryDataProvider: LibraryDataProvider {
        get { self[LibraryDataProviderDefault.self] }
        set { self[LibraryDataProviderDefault.self] = newValue }
    }
}
