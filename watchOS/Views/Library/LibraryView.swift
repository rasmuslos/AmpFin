//
//  LibraryView.swift
//  watchOS
//
//  Created by Rasmus Krämer on 14.11.23.
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.defaultMinListRowHeight) var defaultRowHeight
    @Environment(\.libraryDataProvider) var dataProvider
    
    var body: some View {
        List {
            NavigationLink(value: TracksDestination()) {
                Label("section.tracks", systemImage: "music.note")
            }
            NavigationLink(value: AlbumsDestination()) {
                Label("section.albums", systemImage: "square.stack")
            }
            
            NavigationLink(value: FavoritesDestination()) {
                Label("section.favorites", systemImage: "heart")
            }
            .disabled(!dataProvider.supportsFavoritesLookup)
            
            NavigationLink(value: ArtistsDestination(albumArtists: true)) {
                Label("section.albumArtists", systemImage: "music.mic")
            }
            .disabled(!dataProvider.supportsArtistLookup)
            NavigationLink(value: ArtistsDestination(albumArtists: false)) {
                Label("section.artists", systemImage: "mic.fill")
            }
            .disabled(!dataProvider.supportsArtistLookup)
        }
        .navigationDestination(for: TracksDestination.self) { _ in
            TracksView()
        }
        .navigationDestination(for: AlbumsDestination.self) { _ in
            AlbumsView()
        }
        .navigationDestination(for: FavoritesDestination.self) { _ in
            FavoritesView()
        }
        .navigationDestination(for: ArtistsDestination.self) { helper in
            ArtistsView(albumOnly: helper.albumArtists)
        }
        .modifier(NowPlayingModifier())
    }
}

// MARK: Destinations

extension LibraryView {
    struct TracksDestination: Hashable {
    }
    struct AlbumsDestination: Hashable {
    }
    struct FavoritesDestination: Hashable {
    }
    struct ArtistsDestination: Hashable {
        let albumArtists: Bool
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
