//
//  AlbumGridItem.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct AlbumCover: View {
    let album: Album
    
    var body: some View {
        VStack(alignment: .leading) {
            ItemImage(cover: album.cover)
            
            Group {
                Text(album.name)
                    .font(.callout)
                Text(album.artists.map { $0.name }.joined(separator: ", "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 7)
            }
            .lineLimit(1)
            .font(.system(size: 15))
        }
        .modifier(AlbumContextMenuModifier(album: album))
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        AlbumCover(album: Album.fixture)
        AlbumCover(album: Album.fixture)
        AlbumCover(album: Album.fixture)
        AlbumCover(album: Album.fixture)
    }
    .padding()
}
