//
//  PlaylistView.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AFBaseKit
import AFPlaybackKit

struct PlaylistView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let playlist: Playlist
    
    @State var tracks = [Track]()
    
    var body: some View {
        List {
            Header(playlist: playlist) { shuffle in
                AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: shuffle)
            }
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .padding(.bottom)
            
            TrackList(tracks: tracks, hideButtons: true)
        }
        .listStyle(.plain)
        .ignoresSafeArea(edges: .top)
        .navigationTitle(playlist.name)
        .modifier(ToolbarModifier())
        .task(fetchTracks)
        .refreshable(action: fetchTracks)
    }
}

extension PlaylistView {
    @Sendable
    func fetchTracks() async {
        tracks = (try? await dataProvider.getPlaylistTracks(playlistId: playlist.id)) ?? []
    }
}

#Preview {
    NavigationStack {
        PlaylistView(playlist: Playlist.fixture)
    }
}
