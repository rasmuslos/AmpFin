//
//  ItemRow.swift
//  watchOS
//
//  Created by Rasmus Krämer on 14.11.23.
//

import SwiftUI
import MusicKit

struct ItemRow: View {
    @Environment(\.defaultMinListRowHeight) var defaultListRowHeight
    
    let item: Item
    
    var body: some View {
        HStack {
            ItemImage(cover: item.cover)
                .frame(height: defaultListRowHeight - 10)
                .padding(.vertical, 5)
                .padding(.trailing, 5)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.caption)
                    .lineLimit(1)
                
                Group {
                    if let track = item as? Track {
                        Text(track.artists.map { $0.name }.joined(separator: ", "))
                    } else if let album = item as? Album {
                        Text(album.artists.map { $0.name }.joined(separator: ", "))
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            
            Spacer()
        }
    }
}
