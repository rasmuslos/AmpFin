//
//  PlaylistsList.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AmpFinKit

struct PlaylistsList: View {
    let playlists: [Playlist]
    
    var body: some View {
        ForEach(playlists) { playlist in
            NavigationLink(value: playlist) {
                PlaylistListRow(playlist: playlist)
            }
            .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
    }
}

#Preview {
    NavigationStack {
        List {
            PlaylistsList(playlists: [
                Playlist.fixture,
                Playlist.fixture,
                Playlist.fixture,
                Playlist.fixture,
                Playlist.fixture,
                Playlist.fixture,
                Playlist.fixture,
            ])
            .padding(.horizontal, 20)
        }
        .listStyle(.plain)
    }
}
