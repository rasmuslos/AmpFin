//
//  AlbumView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

struct AlbumView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.libraryDataProvider) private var dataProvider
    
    @State private var viewModel: AlbumViewModel
    
    init(album: Album) {
        viewModel = .init(album)
    }
    
    var body: some View {
        List {
            Header()
            .padding(.bottom, 4)
            
            TrackList(tracks: viewModel.tracks, container: viewModel.album)
                .padding(.horizontal, 20)
            
            if let overview = viewModel.album.overview, overview.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                Text(overview)
            }
            
            VStack(alignment: .leading) {
                if let releaseDate = viewModel.album.releaseDate {
                    Text(releaseDate, style: .date)
                }
                
                Text(viewModel.runtime.duration)
            }
            .font(.subheadline)
            .listRowSeparator(.hidden, edges: .top)
            .foregroundStyle(.secondary)
            
            AdditionalAlbums(album: viewModel.album)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .modifier(ToolbarModifier())
        .environment(viewModel)
        .modifier(NowPlaying.SafeAreaModifier())
        .sensoryFeedback(.error, trigger: viewModel.errorFeedback)
        .task {
            viewModel.dataProvider = dataProvider
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .userActivity("io.rfk.ampfin.album") {
            $0.title = viewModel.album.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = viewModel.album.id
            $0.targetContentIdentifier = "album:\(viewModel.album.id)"
            $0.userInfo = [
                "albumId": viewModel.album.id
            ]
            $0.webpageURL = URL(string: JellyfinClient.shared.serverUrl.appending(path: "web").absoluteString + "#")!.appending(path: "details").appending(queryItems: [
                .init(name: "id", value: viewModel.album.id),
            ])
        }
    }
}

#Preview {
    NavigationStack {
        AlbumView(album: Album.fixture)
    }
}
