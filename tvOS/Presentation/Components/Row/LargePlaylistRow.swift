//
//  LargeAlbumsRow.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI
import AFBase

struct LargePlaylistRow: View {
    let playlists: [Playlist]
    
    var body: some View {
        let size = (UIScreen.main.bounds.width - 90 * 3) / 2
        
        ScrollView(.horizontal) {
            LazyHStack(spacing: 40) {
                ForEach(playlists) { playlist in
                    LargePlaylistItem(playlist: playlist)
                        .frame(width: size)
                        .padding(.vertical, 45)
                }
            }
            .padding(.horizontal, 45)
        }
        .focusSection()
    }
}

#Preview {
    ScrollView {
        LargePlaylistRow(playlists: [
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
        ])
    }
    .ignoresSafeArea()
}
