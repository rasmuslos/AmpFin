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
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: PlaylistViewModel
    
    init(playlist: Playlist) {
        viewModel = .init(playlist)
    }
    
    var body: some View {
        List {
            Header()
                .padding(.bottom, 8)
            
            TrackList(tracks: viewModel.tracks, container: viewModel.playlist, preview: viewModel.editMode == .active, deleteCallback: viewModel.removeTrack, moveCallback: viewModel.moveTrack)
                .padding(.horizontal, 20)
        }
        .listStyle(.plain)
        .ignoresSafeArea(edges: .top)
        .navigationTitle(viewModel.playlist.name)
        .sensoryFeedback(.error, trigger: viewModel.errorFeedback)
        .alert("playlist.delete.alert", isPresented: $viewModel.deleteAlertPresented) {
            Button(role: .cancel) {
                viewModel.deleteAlertPresented = false
            } label: {
                Text("cancel")
            }
            Button(role: .destructive) {
                viewModel.delete()
            } label: {
                Text("playlist.delete.finalize")
            }
        }
        .modifier(ToolbarModifier())
        .environment(\.editMode, $viewModel.editMode)
        .environment(\.displayContext, .playlist)
        .environment(viewModel)
        .modifier(NowPlaying.SafeAreaModifier())
        .task {
            viewModel.dataProvider = dataProvider
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .onChange(of: viewModel.dismiss) {
            
        }
        .userActivity("io.rfk.ampfin.playlist") {
            $0.title = viewModel.playlist.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = viewModel.playlist.id
            $0.targetContentIdentifier = "playlist:\(viewModel.playlist.id)"
            $0.userInfo = [
                "playlistId": viewModel.playlist.id
            ]
            $0.webpageURL = URL(string: JellyfinClient.shared.serverUrl.appending(path: "web").absoluteString + "#")!.appending(path: "details").appending(queryItems: [
                .init(name: "id", value: viewModel.playlist.id),
            ])
        }
    }
}

#Preview {
    NavigationStack {
        PlaylistView(playlist: Playlist.fixture)
    }
}
