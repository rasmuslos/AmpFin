//
//  PlaylistView.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AFBase
import AFPlayback

struct PlaylistView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    @Environment(\.libraryOnline) private var libraryOnline
    
    let playlist: Playlist
    
    @State private var tracks = [Track]()
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        List {
            Header(playlist: playlist) { shuffle in
                AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: shuffle, playbackInfo: .init(container: playlist))
            }
            
            TrackList(tracks: tracks, hideButtons: true, deleteCallback: libraryOnline ? removeTrack : nil, moveCallback: libraryOnline ? moveTrack : nil)
                .padding(.top, 4)
                .padding(.horizontal, 20)
        }
        .environment(\.editMode, $editMode)
        .listStyle(.plain)
        .ignoresSafeArea(edges: .top)
        .navigationTitle(playlist.name)
        .modifier(ToolbarModifier(playlist: playlist, tracks: $tracks, editMode: $editMode))
        .modifier(NowPlayingBarSafeAreaModifier())
        .userActivity("io.rfk.ampfin.playlist") {
            $0.title = playlist.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = playlist.id
            $0.userInfo = [
                "playlistId": playlist.id
            ]
        }
        .task { await fetchTracks() }
        .refreshable { await fetchTracks() }
    }
}

extension PlaylistView {
    func fetchTracks() async {
        if let tracks = try? await dataProvider.getTracks(playlistId: playlist.id) {
            self.tracks = tracks
        }
    }
    
    func removeTrack(track: Track) {
        Task {
            do {
                try await JellyfinClient.shared.remove(trackId: track.id, playlistId: playlist.id)
                
                withAnimation {
                    if let firstMatching = tracks.firstIndex(of: track) {
                        tracks.remove(at: firstMatching)
                        
                        playlist.trackCount = tracks.count
                        playlist.duration = tracks.reduce(0, { $0 + $1.runtime })
                    }
                }
            } catch {}
        }
    }
    
    func moveTrack(track: Track, to: Int) {
        Task {
            var to = to
            
            if tracks.firstIndex(of: track)! < to {
                to -= 1
            }
            
            try? await JellyfinClient.shared.move(trackId: track.id, index: to, playlistId: playlist.id)
        }
    }
}

#Preview {
    NavigationStack {
        PlaylistView(playlist: Playlist.fixture)
    }
}
