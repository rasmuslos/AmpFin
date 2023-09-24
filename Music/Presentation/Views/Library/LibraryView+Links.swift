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
        
        @Environment(\.libraryOnline) var libraryOnline
        
        var body: some View {
            Group {
                NavigationLink(destination: TracksView()) {
                    Label("Tracks", systemImage: "music.note")
                }
                NavigationLink(destination: AlbumsView()) {
                    Label("Albums", systemImage: "square.stack")
                }
                
                NavigationLink(destination: FavoritesView()) {
                    Label("Favorites", systemImage: "heart")
                }
                .disabled(!libraryOnline)
                
                NavigationLink(destination: ArtistsView(albumOnly: true)) {
                    Label("Album Artists", systemImage: "music.mic")
                }
                .disabled(!libraryOnline)
                NavigationLink(destination: ArtistsView(albumOnly: false)) {
                    Label("Artists", systemImage: "mic.fill")
                }
                .disabled(!libraryOnline)
                /*
                 Not really possible without knowing the library id
                 
                NavigationLink(destination: Text("oof")) {
                    Label("Genres", systemImage: "guitars")
                }
                 */
            }
            .font(.headline)
        }
    }
}
