//
//  SplitView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 08.04.24.
//

import Foundation
import Defaults
import SwiftUI

struct SidebarView: View {
    @Default(.lastSidebarSelection) private var selection
    
    var body: some View {
        NavigationSplitView {
            List() {
                ForEach(DataProvider.allCases, id: \.hashValue) {
                    ProviderSection(provider: $0, selection: $selection)
                }
            }
        } detail: {
            selection.section.content
                .environment(\.libraryDataProvider, selection.provider.libraryProvider)
        }
    }
}

extension SidebarView {
    struct Selection: Codable, _DefaultsSerializable {
        var provider: DataProvider
        var section: LibrarySection
    }
    
    enum DataProvider: Codable, CaseIterable {
        case online
        case offline
    }
    
    enum LibrarySection: Codable, CaseIterable {
        case tracks
        case albums
        case playlists
        case favorites
        case albumArtists
        case artists
    }
}

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
                return SidebarView.LibrarySection.allCases
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
        }
    }
    
    var content: some View {
        NavigationStack {
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
            }
        }
    }
}

private extension Defaults.Keys {
    static let lastSidebarSelection = Key<SidebarView.Selection>("lastSidebarSelection", default: .init(provider: .online, section: .tracks))
}

#Preview {
    SidebarView()
}
