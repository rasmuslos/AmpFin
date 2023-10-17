//
//  AlbumGrid.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct AlbumGrid: View {
    let albums: [Album]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
            ForEach(Array(albums.enumerated()), id: \.offset) { index, album in
                NavigationLink {
                    AlbumView(album: album)
                } label: {
                    AlbumCover(album: album)
                        .padding(.trailing, index % 2 == 0 ? 5 : 0)
                        .padding(.leading, index % 2 == 1 ? 5 : 0)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    AlbumGrid(albums: [
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
    ])
    .padding()
}
