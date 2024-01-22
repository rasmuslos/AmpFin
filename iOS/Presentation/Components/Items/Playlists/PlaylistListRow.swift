//
//  PlaylistListRow.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AFBase

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
        .dropDestination(for: Track.self) { tracks, _ in
            Task {
                try await playlist.add(trackIds: tracks.map { $0.id })
            }
            
            return true
        }
        .swipeActions(edge: .leading) {
            Button {
                
            } label: {
                Image(systemName: "arrow.down")
                    .tint(.green)
            }
        }
        .swipeActions(edge: .trailing) {
            Button {
                Task {
                    await playlist.setFavorite(favorite: !playlist.favorite)
                }
            } label: {
                Image(systemName: playlist.favorite ? "heart.fill" : "heart")
                    .tint(.orange)
            }
        }
    }
}
