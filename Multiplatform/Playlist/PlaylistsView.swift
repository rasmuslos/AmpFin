//
//  PlaylistsView.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AmpFinKit

struct PlaylistsView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    @State private var failed = false
    @State private var playlists = [Playlist]()
    
    var body: some View {
        Group {
            if !playlists.isEmpty {
                List {
                    PlaylistsList(playlists: playlists)
                        .padding(.horizontal, 20)
                }
                .listStyle(.plain)
            } else if failed {
                ErrorView()
            } else {
                LoadingView()
                    .task { await loadPlaylists() }
            }
        }
        .navigationTitle("title.playlists")
        .modifier(NowPlaying.SafeAreaModifier())
        .refreshable { await loadPlaylists() }
    }
    
    private func loadPlaylists() async {
        failed = false
        
        guard let playlists = try? await dataProvider.playlists(search: nil) else {
            failed = true
            return
        }
        
        self.playlists = playlists
    }
}

#Preview {
    NavigationStack {
        PlaylistsView()
    }
}
