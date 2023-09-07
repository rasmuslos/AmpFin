//
//  SongListItem.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct SongListItem: View {
    let item: SongItem
    var album: AlbumItem? = nil
    
    var body: some View {
        let showArtist = album == nil || !item.artists.elementsEqual(album!.artists) { $0.id == $1.id }
        
        HStack {
            if album != nil {
                Text(String(item.index))
                    .frame(width: 23)
                    // .padding(.horizontal, 7)
            } else {
                ItemImage(cover: item.cover)
                    .frame(width: 45)
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .lineLimit(1)
                    .font(.headline)
                    .padding(.vertical, showArtist ? 0 : 6)
                
                if showArtist {
                    Text(item.artists.map { $0.name }.joined(separator: ", "))
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 5)
            
            Spacer()
            Menu {
                
            } label: {
                Image(systemName: "ellipsis")
                    .renderingMode(.original)
                    .foregroundStyle(Color(UIColor.label))
            }
        }
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
