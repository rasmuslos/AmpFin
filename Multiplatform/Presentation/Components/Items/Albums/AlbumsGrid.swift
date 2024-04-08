//
//  AlbumGrid.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase

struct AlbumGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let albums: [Album]
    
    /// Expected album count used to display placeholders
    var count: Int = 0
    /// Function invoked when the users reaches the last loaded albums. Should mutate the `albums` parameter
    var loadMore: (() async -> Void)? = nil
    
    @State private var working = false
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 160.0 : 240.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 16)], spacing: 10) {
            ForEach(Array(albums.enumerated()), id: \.offset) { index, album in
                NavigationLink {
                    AlbumView(album: album)
                } label: {
                    AlbumCover(album: album)
                }
                .buttonStyle(.plain)
                .onAppear { expand(index: index) }
            }
            
            ForEach(0..<(max(0, count - albums.count)), id: \.hashValue) { _ in
                AlbumCover.placeholder
                    .onAppear { expand(index: -1) }
            }
        }
    }
}

private extension AlbumGrid {
    func expand(index: Int) {
        if !working && count > albums.count && (index == -1 || index > albums.count - 20), let loadMore = loadMore {
            working = true
            
            Task.detached {
                await loadMore()
                working = false
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

#Preview {
    AlbumGrid(albums: [
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
    ], count: 200)
    .padding()
}
