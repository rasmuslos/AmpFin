//
//  AlbumGridItem.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct AlbumGridItem: View {
    let item: AlbumItem
    
    var body: some View {
        VStack(alignment: .leading) {
            ItemImage(cover: item.cover)
            
            Group {
                Text(item.name)
                Text(item.artists.map { $0.name }.joined(separator: ", "))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 7)
            }
            .lineLimit(1)
            .font(.system(size: 15))
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        AlbumGridItem(item: AlbumItem.fixture)
        AlbumGridItem(item: AlbumItem.fixture)
        AlbumGridItem(item: AlbumItem.fixture)
        AlbumGridItem(item: AlbumItem.fixture)
    }
    .padding()
}
