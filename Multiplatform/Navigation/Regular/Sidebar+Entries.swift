//
//  Sidebar+Entries.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import Foundation
import Defaults
import SwiftUI
import AFBase

extension SidebarView {
    struct Selection: Hashable, Equatable, Codable, _DefaultsSerializable {
        var provider: DataProvider
        var section: LibrarySection
    }
    
    enum DataProvider: Codable, CaseIterable {
        case online
        case offline
    }
    
    enum LibrarySection: Hashable, Equatable, Codable {
        case tracks
        case albums
        case playlists
        case favorites
        case albumArtists
        case artists
        
        // Special:
        case search
        case playlist(id: String)
    }
}

// MARK: Providers

extension SidebarView.DataProvider {
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
    var sections: [SidebarView.LibrarySection] {
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

extension SidebarView.LibrarySection {
    var title: LocalizedStringKey {
        switch self {
            case .tracks:
                return "section.tracks"
            case .albums:
                return "section.albums"
            case .playlists:
                return "section.playlists"
            case .favorites:
                return "title.favorites"
            case .albumArtists:
                return "title.albumArtists"
            case .artists:
                return "section.artists"
            default:
                return ""
        }
    }
    var icon: String {
        switch self {
            case .tracks:
                return "music.note"
            case .albums:
                return "square.stack"
            case .playlists:
                return "music.note.list"
            case .favorites:
                return "heart"
            case .albumArtists:
                return "music.mic"
            case .artists:
                return "mic.fill"
            default:
                return ""
        }
    }
    
    var content: some View {
        Group {
            switch self {
                case .tracks:
                    TracksView()
                case .albums:
                    AlbumsView()
                case .playlists:
                    PlaylistsView()
                case .favorites:
                    FavoritesView()
                case .albumArtists:
                    ArtistsView(albumOnly: true)
                case .artists:
                    ArtistsView(albumOnly: false)
                case .search:
                    SearchView()
                case .playlist(let id):
                    PlaylistLoadView(playlistId: id)
            }
        }
    }
}
