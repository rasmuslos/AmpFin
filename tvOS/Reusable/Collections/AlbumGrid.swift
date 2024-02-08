//
//  AlbumsRow.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI
import AFBase

struct AlbumGrid: View {
    let albums: [Album]
    var columns = 6
    
    var body: some View {
        let size = (UIScreen.main.bounds.width - (45 * 2 + 50 * CGFloat(columns - 1))) / CGFloat(columns)
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(albums) { album in
                    AlbumGridItem(album: album)
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

extension AlbumGrid {
    struct AlbumGridItem: View {
        let album: Album
        
        @FocusState var isFocused: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                NavigationLink(destination: Text(album.name)) {
                    ItemImage(cover: album.cover)
                }
                .focused($isFocused)
                .buttonStyle(.card)
                .padding(.bottom, 15)
                
                VStack {
                    Text(album.name)
                        .lineLimit(1)
                    Text(album.artistName)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .offset(y: isFocused ? 25 : 0)
                .animation(.interactiveSpring, value: isFocused)
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
        Album.fixture,
        Album.fixture,
        Album.fixture,
    ])
}
