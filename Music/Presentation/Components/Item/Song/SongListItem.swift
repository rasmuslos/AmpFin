//
//  SongListItem.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct SongListItem: View {
    let item: SongItem
    
    var body: some View {
        HStack {
            ItemImage(cover: item.cover)
                .frame(width: 45)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .lineLimit(1)
                    .font(.headline)
                
                Text(item.artists.map { $0.name }.joined(separator: ", "))
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 5)
            
            Spacer()
            Menu {
                
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.primary)
            }
        }
        .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
        .padding(.horizontal)
    }
}

#Preview {
    List {
        SongListItem(item: SongItem.fixture)
        SongListItem(item: SongItem.fixture)
        SongListItem(item: SongItem.fixture)
        SongListItem(item: SongItem.fixture)
    }
    .listStyle(.plain)
}
