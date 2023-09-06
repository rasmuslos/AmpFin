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
        
        var body: some View {
            Group {
                NavigationLink(destination: SongsView()) {
                    Label("Songs", systemImage: "music.note")
                }
                NavigationLink(destination: AlbumsView()) {
                    Label("Albums", systemImage: "square.stack")
                }
                NavigationLink(destination: Text("oof")) {
                    Label("Album Artists", systemImage: "music.mic")
                }
                NavigationLink(destination: Text("oof")) {
                    Label("Artists", systemImage: "mic.fill")
                }
                NavigationLink(destination: Text("oof")) {
                    Label("Genres", systemImage: "guitars")
                }
            }
            .font(.headline)
        }
    }
}
