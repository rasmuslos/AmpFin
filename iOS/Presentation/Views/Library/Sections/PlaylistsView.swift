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
#if targetEnvironment(macCatalyst)
    @Environment(NowPlayingViewState.self) private var viewState
#endif
    
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
#if targetEnvironment(macCatalyst)
        .toolbar(viewState.presented ? .hidden : .automatic,
                for: .navigationBar)
#endif
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
