//
//  PlaylistCover.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI
import AFBaseKit

struct PlaylistCover: View {
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

#Preview {
    AlbumCover(album: Album.fixture)
}
