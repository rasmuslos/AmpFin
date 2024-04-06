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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        let minWidth = horizontalSizeClass == .compact ? 160.0 : 240.0
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth, maximum: 400), spacing: 16)],
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        let minWidth = horizontalSizeClass == .compact ? 160.0 : 240.0
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth, maximum: 400), spacing: 16)],
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
