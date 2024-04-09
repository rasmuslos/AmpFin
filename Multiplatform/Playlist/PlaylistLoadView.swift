//
//  PlaylistLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AFBase

struct PlaylistLoadView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let playlistId: String
    
    @State private var failed = false
    @State private var playlist: Playlist?
    
    var body: some View {
        if failed {
            ErrorView()
        } else if let playlist = playlist {
            PlaylistView(playlist: playlist)
        } else {
            LoadingView()
                .task {
                    if let playlist = try? await dataProvider.getPlaylist(playlistId: playlistId) {
                        self.playlist = playlist
                    } else {
                        self.failed = true
                    }
                }
        }
    }
}
