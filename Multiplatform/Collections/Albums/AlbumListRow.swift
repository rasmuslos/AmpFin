//
//  AlbumListRow.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI
import AmpFinKit

struct AlbumListRow: View {
    let album: Album
    
    var body: some View {
        HStack(spacing: 0) {
            ItemImage(cover: album.cover)
                .frame(width: 60)
                .padding(.trailing, 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .lineLimit(1)
                    .font(.body)
                
                if let artistName = album.artistName {
                    Text(artistName)
                        .lineLimit(1)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 8)
            
            DownloadIndicator(item: album)
        }
        .modifier(AlbumContextMenuModifier(album: album))
    }
}


#Preview {
    List {
        AlbumListRow(album: .fixture)
        AlbumListRow(album: .fixture)
        AlbumListRow(album: .fixture)
        AlbumListRow(album: .fixture)
        AlbumListRow(album: .fixture)
    }
    .listStyle(.plain)
}
