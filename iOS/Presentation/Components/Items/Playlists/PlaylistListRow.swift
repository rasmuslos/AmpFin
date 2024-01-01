//
//  PlaylistListRow.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AFBaseKit

struct PlaylistListRow: View {
    let playlist: Playlist
    
    var body: some View {
        HStack {
            ItemImage(cover: playlist.cover)
                .frame(width: 60)
                .padding(.trailing, 5)
            
            VStack(alignment: .leading) {
                Text(playlist.name)
                Text("playlist.trackCount \(playlist.trackCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}
