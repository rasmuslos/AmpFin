//
//  AlbumGrid.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase

struct AlbumsGrid: View {
    let albums: [Album]
    @Environment(\.displayScale) var displayScale
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 400 / displayScale, maximum: 400))],
                  spacing: 10) {
            ForEach(Array(albums.enumerated()), id: \.offset) { index, album in
                NavigationLink {
                    AlbumView(album: album)
                } label: {
                    AlbumCover(album: album)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AlbumsGridLazyLoad: View {
    let albums: [Album]
    let loadMore: () -> Void
    @Environment(\.displayScale) var displayScale
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 400 / displayScale, maximum: 400))],
                  spacing: 10) {
            ForEach(Array(albums.enumerated()), id: \.offset) { index, album in
                NavigationLink {
                    AlbumView(album: album)
                } label: {
                    AlbumCover(album: album)
                        .onAppear {
                            if album == albums.last {
                                loadMore()
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    AlbumsGrid(albums: [
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
    ])
    .padding()
}
