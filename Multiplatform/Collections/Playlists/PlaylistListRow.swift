//
//  PlaylistListRow.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AFBase
import AFOffline

struct PlaylistListRow: View {
    let playlist: Playlist
    let offlineTracker: ItemOfflineTracker
    
    init(playlist: Playlist) {
        self.playlist = playlist
        offlineTracker = playlist.offlineTracker
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ItemImage(cover: playlist.cover)
                .frame(width: 60)
                .padding(.trailing, .connectedSpacing)
            
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
                if offlineTracker.status == .none {
                    Task {
                        try! await OfflineManager.shared.download(playlist: playlist)
                    }
                } else if offlineTracker.status == .downloaded {
                    try! OfflineManager.shared.delete(playlistId: playlist.id)
                }
            } label: {
                switch offlineTracker.status {
                    case .none:
                        Label("download", systemImage: "arrow.down")
                            .tint(.green)
                    case .working:
                        ProgressView()
                    case .downloaded:
                        Label("download.remove", systemImage: "xmark")
                            .tint(.red)
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button {
                Task {
                    await playlist.setFavorite(favorite: !playlist.favorite)
                }
            } label: {
                Label("favorite", systemImage: playlist.favorite ? "heart.fill" : "heart")
                    .tint(.orange)
            }
        }
    }
}
