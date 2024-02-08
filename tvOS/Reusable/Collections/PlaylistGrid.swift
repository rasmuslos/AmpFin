//
//  PlaylistsRow.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI
import AFBase

struct PlaylistGrid: View {
    let playlists: [Playlist]
    var columns = 6
    
    var body: some View {
        let size = (UIScreen.main.bounds.width - (45 * 2 + 50 * CGFloat(columns - 1))) / CGFloat(columns)
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(playlists) { playlist in
                    PlaylistGridItem(playlist: playlist)
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

extension PlaylistGrid {
    struct PlaylistGridItem: View {
        let playlist: Playlist
        
        @FocusState var isFocused: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                NavigationLink(destination: PlaylistView(playlist: playlist)) {
                    ItemImage(cover: playlist.cover)
                }
                .focused($isFocused)
                .buttonStyle(.card)
                .padding(.bottom, 15)
                
                HStack {
                    Text(playlist.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    + Text(verbatim: " • ")
                    + Text("\(playlist.trackCount) tracks.count")
                }
                .lineLimit(1)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                .frame(maxWidth: .infinity)
                .offset(y: isFocused ? 25 : 0)
                .animation(.interactiveSpring, value: isFocused)
            }
        }
    }
}

#Preview {
    PlaylistGrid(playlists: [
        .fixture,
        .fixture,
        .fixture,
        .fixture,
        .fixture,
        .fixture,
        .fixture,
    ])
}

