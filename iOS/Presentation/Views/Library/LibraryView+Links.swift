//
//  LibraryView+Links.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

extension LibraryView {
    struct Links: View {
        static let count = 5
        
        @Environment(\.libraryDataProvider) var dataProvider
        
        var body: some View {
            Group {
                NavigationLink(destination: TracksView()) {
                    Label("title.tracks", systemImage: "music.note")
                }
                NavigationLink(destination: AlbumsView()) {
                    Label("title.albums", systemImage: "square.stack")
                }
                
                NavigationLink(destination: FavoritesView()) {
                    Label("title.favorites", systemImage: "heart")
                }
                .disabled(!dataProvider.supportsFavoritesLookup)
                
                NavigationLink(destination: ArtistsView(albumOnly: true)) {
                    Label("title.albumArtists", systemImage: "music.mic")
                }
                .disabled(!dataProvider.supportsArtistLookup)
                NavigationLink(destination: ArtistsView(albumOnly: false)) {
                    Label("title.artists", systemImage: "mic.fill")
                }
                .disabled(!dataProvider.supportsArtistLookup)
                /*
                 Not really possible without knowing the library id
                 
                NavigationLink(destination: Text(":)")) {
                    Label("Genres", systemImage: "guitars")
                }
                 */
            }
            .font(.headline)
        }
    }
}
