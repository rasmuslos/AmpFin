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
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let album: Album
    
    @State private var tracks = [Track]()
    
    @State private var imageColors = ImageColors()
    @State private var toolbarBackgroundVisible = false
    
    var body: some View {
        List {
            Header(album: album, imageColors: imageColors, toolbarBackgroundVisible: $toolbarBackgroundVisible) { shuffle in
                AudioPlayer.current.startPlayback(tracks: tracks.sorted { $0.index < $1.index }, startIndex: 0, shuffle: shuffle, playbackInfo: .init(container: album))
            }
            .padding(.bottom, 8)
            
            TrackList(tracks: tracks, container: album)
                .padding(.horizontal, 20)
            
            if let overview = album.overview, overview.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                Text(overview)
            }
            
            VStack(alignment: .leading) {
                if let releaseDate = album.releaseDate {
                    Text(releaseDate, style: .date)
                }
                
                Text(tracks.reduce(0, { $0 + $1.runtime }).duration)
            }
            .font(.subheadline)
            .listRowSeparator(.hidden, edges: .top)
            .foregroundStyle(.secondary)
            
            AdditionalAlbums(album: album)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .modifier(
            ToolbarModifier(album: album, imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible) {
                AudioPlayer.current.queueTracks(
                    tracks.sorted { $0.index < $1.index },
                    index: $0 ? 0 : AudioPlayer.current.queue.count,
                    playbackInfo: .init(container: album, queueLocation: $0 ? .now : .later))
            }
        )
        .modifier(NowPlaying.SafeAreaModifier())
        .task {
            await imageColors.update(cover: album.cover)
        }
        .task {
            await loadTracks()
        }
        .refreshable {
            await loadTracks()
        }
        .userActivity("io.rfk.ampfin.album") {
            $0.title = album.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = album.id
            $0.targetContentIdentifier = "album:\(album.id)"
            $0.userInfo = [
                "albumId": album.id
            ]
            $0.webpageURL = URL(string: JellyfinClient.shared.serverUrl.appending(path: "web").absoluteString + "#")!.appending(path: "details").appending(queryItems: [
                .init(name: "id", value: album.id),
            ])
        }
    }
    
    private func loadTracks() async {
        guard let tracks = try? await dataProvider.tracks(albumId: album.id) else {
            return
        }
        
        self.tracks = tracks
    }
}

#Preview {
    NavigationStack {
        AlbumView(album: Album.fixture)
    }
}
