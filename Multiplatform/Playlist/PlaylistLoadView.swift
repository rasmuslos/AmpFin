//
//  PlaylistLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AmpFinKit

struct PlaylistLoadView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let playlistId: String
    
    @State private var failed = false
    @State private var playlist: Playlist?
    
    var body: some View {
        if failed {
            ErrorView()
                .refreshable { await loadPlaylist() }
        } else if let playlist {
            PlaylistView(playlist: playlist)
        } else {
            LoadingView()
                .task { await loadPlaylist() }
                .refreshable { await loadPlaylist() }
        }
    }
    
    private func loadPlaylist() async {
        guard let playlist = try? await dataProvider.playlist(identifier: playlistId) else {
            failed = true
            return
        }
        
        self.playlist = playlist
    }
}
