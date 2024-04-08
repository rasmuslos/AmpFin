//
//  PlaylistsView.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AFBase

struct PlaylistsView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var playlists: [Playlist]?
    @State var failed = false
    
    var body: some View {
        Group {
            if let playlists = playlists {
                List {
                    PlaylistsList(playlists: playlists)
                }
            } else if failed {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.playlists")
        .task { await fetchPlaylists() }
        .refreshable { await fetchPlaylists() }
        .modifier(NowPlayingBarSafeAreaModifier())
    }
}

extension PlaylistsView {
    func fetchPlaylists() async {
        failed = false
        
        do {
            playlists = try await dataProvider.getPlaylists()
        } catch {
            failed = true
        }
    }
}

#Preview {
    PlaylistsView()
}
