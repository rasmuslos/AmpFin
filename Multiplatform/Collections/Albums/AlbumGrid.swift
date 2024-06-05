//
//  AlbumGrid.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AmpFinKit

struct AlbumGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let albums: [Album]
    
    /// Expected album count used to display placeholders
    var count: Int = 0
    /// Function invoked when the users reaches the last loaded albums. Should mutate the `albums` parameter
    var loadMore: (() -> Void)? = nil
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 160.0 : 200.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 12)], spacing: 16) {
            ForEach(albums) { album in
                NavigationLink(value: album) {
                    AlbumCover(album: album)
                }
                .buttonStyle(.plain)
                .onAppear {
                    if album == albums.last {
                        loadMore?()
                    }
                }
            }
            
            ForEach(0..<(max(0, count - albums.count)), id: \.hashValue) { _ in
                AlbumCover.placeholder
                    .onAppear { loadMore?() }
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
