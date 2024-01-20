//
//  PlaylistsRow.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI
import AFBaseKit

struct PlaylistsRow: View {
    let playlists: [Playlist]
    var columns = 6
    
    var body: some View {
        let size = (UIScreen.main.bounds.width - (45 * 2 + 50 * CGFloat(columns - 1))) / CGFloat(columns)
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(playlists) { playlist in
                    PlaylistCover(playlist: playlist)
                        .frame(width: size)
                        .padding(.leading, 37)
                        .padding(.vertical, 35)
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 45)
        }
    }
}

struct PlaylistsRowTitle: View {
    let title: String
    let playlists: [Playlist]
    
    var body: some View {
        VStack {
            RowTitle(title: title)
                .padding(.bottom, -30)
            PlaylistsRow(playlists: playlists)
        }
        .focusSection()
    }
}

#Preview {
    AlbumsRowTitle(title: "Hello, World!", albums: [
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
    ])
}
