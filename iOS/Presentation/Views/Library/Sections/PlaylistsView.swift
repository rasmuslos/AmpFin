//
//  PlaylistsView.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AFBaseKit

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
        .task(loadPlaylists)
        .refreshable(action: loadPlaylists)
        .modifier(NowPlayingBarSafeAreaModifier())
    }
}

extension PlaylistsView {
    @Sendable
    func loadPlaylists() async {
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
