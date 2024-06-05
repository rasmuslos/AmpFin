//
//  Sidebar+Entries.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import Foundation
import Defaults
import SwiftUI
import AmpFinKit

internal extension Sidebar {
    struct Selection: Hashable, Equatable, Codable, Defaults.Serializable {
        var provider: DataProvider?
        var panel: Panel
    }
    
    enum DataProvider: Codable, CaseIterable {
        case online
        case offline
    }
    
    enum Panel: Hashable, Equatable, Codable {
        case tracks
        case albums
        case playlists
        case favorites
        case albumArtists
        case artists
        
        // Special:
        case search
        case playlist(id: String)
        case album(id: String)
        case artist(id: String)
    }
}

// MARK: Providers

internal extension Sidebar.DataProvider {
    var libraryProvider: LibraryDataProvider {
        switch self {
            case .online:
                return OnlineLibraryDataProvider()
            case .offline:
                return OfflineLibraryDataProvider()
        }
    }
    var title: LocalizedStringKey {
        switch self {
            case .online:
                "title.library"
            case .offline:
                "title.downloads"
        }
    }
    var panels: [Sidebar.Panel] {
        switch self {
            case .online:
                return [
                    .tracks,
                    .albums,
                    .playlists,
                    .favorites,
                    .artists,
                    .albumArtists,
                ]
            case .offline:
                return [
                    .tracks,
                    .albums,
                    .playlists,
                    .favorites,
                ]
        }
    }
}

// MARK: Sections

internal extension Sidebar.Panel {
    var title: LocalizedStringKey? {
        switch self {
            case .tracks:
                return "title.tracks"
            case .albums:
                return "title.albums"
            case .playlists:
                return "title.playlists"
            case .favorites:
                return "title.favorites"
            case .albumArtists:
                return "title.albumArtists"
            case .artists:
                return "title.artists"
            default:
                return nil
        }
    }
    var icon: String? {
        switch self {
            case .tracks:
                return "music.note"
            case .albums:
                return "square.stack"
            case .playlists:
                return "music.note.list"
            case .favorites:
                return "star"
            case .albumArtists:
                return "music.mic"
            case .artists:
                return "mic.fill"
            default:
                return nil
        }
    }
    
    @ViewBuilder
    var content: some View {
        switch self {
            case .tracks:
                TracksView(favoritesOnly: false)
            case .albums:
                AlbumsView()
            case .playlists:
                PlaylistsView()
            case .favorites:
                TracksView(favoritesOnly: true)
            case .albumArtists:
                ArtistsView(albumOnly: true)
            case .artists:
                ArtistsView(albumOnly: false)
                
            case .search:
                EmptyView()
                
            case .playlist(let id):
                PlaylistLoadView(playlistId: id)
            case .album(let id):
                AlbumLoadView(albumId: id)
            case .artist(let id):
                ArtistLoadView(artistId: id)
        }
    }
}
