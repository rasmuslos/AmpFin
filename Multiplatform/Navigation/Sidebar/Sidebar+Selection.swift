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
        
        case offlineTracks
        case offlineAlbums
        case offlineFavorites
        case offlinePlaylists
        
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
                    .offlineTracks,
                    .offlineAlbums,
                    .offlinePlaylists,
                    .offlineFavorites,
                ]
        }
    }
}

// MARK: Sections

internal extension Sidebar.Panel {
    var title: LocalizedStringKey? {
        switch self {
            case .offlineTracks, .tracks:
                return "title.tracks"
            case .offlineAlbums, .albums:
                return "title.albums"
            case .offlinePlaylists, .playlists:
                return "title.playlists"
            case .offlineFavorites, .favorites:
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
            case .offlineTracks, .tracks:
                return "music.note"
            case .offlineAlbums, .albums:
                return "square.stack"
            case .offlinePlaylists, .playlists:
                return "music.note.list"
            case .offlineFavorites, .favorites:
                return "heart"
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
            case .offlineTracks, .tracks:
                TracksView(favoritesOnly: false)
            case .offlineAlbums, .albums:
                AlbumsView()
            case .offlinePlaylists, .playlists:
                PlaylistsView()
            case .offlineFavorites, .favorites:
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
