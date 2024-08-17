//
//  PlaylistView.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback

struct PlaylistView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let playlist: Playlist
    
    @State private var toolbarVisible = false
    
    @State private var tracks = [Track]()
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        List {
            Header(playlist: playlist, toolbarVisible: $toolbarVisible) { shuffle in
                AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: shuffle, playbackInfo: .init(container: playlist))
            }
            .padding(.bottom, 8)
            
            TrackList(tracks: tracks, container: playlist, deleteCallback: JellyfinClient.shared.online ? removeTrack : nil, moveCallback: JellyfinClient.shared.online ? moveTrack : nil)
                .padding(.horizontal, 20)
        }
        .listStyle(.plain)
        .environment(\.editMode, $editMode)
        .environment(\.displayContext, .playlist)
        .navigationTitle(playlist.name)
        .ignoresSafeArea(edges: .top)
        .modifier(ToolbarModifier(playlist: playlist, toolbarVisible: $toolbarVisible, tracks: $tracks, editMode: $editMode))
        .modifier(NowPlaying.SafeAreaModifier())
        .task { await loadTracks() }
        .refreshable { await loadTracks() }
        .userActivity("io.rfk.ampfin.playlist") {
            $0.title = playlist.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = playlist.id
            $0.targetContentIdentifier = "playlist:\(playlist.id)"
            $0.userInfo = [
                "playlistId": playlist.id
            ]
            $0.webpageURL = URL(string: JellyfinClient.shared.serverUrl.appending(path: "web").absoluteString + "#")!.appending(path: "details").appending(queryItems: [
                .init(name: "id", value: playlist.id),
            ])
        }
    }
}

private extension PlaylistView {
    func loadTracks() async {
        guard let tracks = try? await dataProvider.tracks(playlistId: playlist.id) else {
            return
        }
        
        self.tracks = tracks
    }
    
    func removeTrack(track: Track) {
        Task {
            try await JellyfinClient.shared.remove(trackId: track.id, playlistId: playlist.id)
            
            withAnimation {
                if let firstMatching = tracks.firstIndex(of: track) {
                    tracks.remove(at: firstMatching)
                    
                    playlist.trackCount = tracks.count
                    playlist.duration = tracks.reduce(0, { $0 + $1.runtime })
                }
            }
        }
    }
    
    func moveTrack(track: Track, to: Int) {
        Task {
            var to = to
            
            if tracks.firstIndex(of: track)! < to {
                to -= 1
            }
            
            try await JellyfinClient.shared.move(trackId: track.id, index: to, playlistId: playlist.id)
        }
    }
}

#Preview {
    NavigationStack {
        PlaylistView(playlist: Playlist.fixture)
    }
}
