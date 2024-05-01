//
//  AlbumView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase
import AFPlayback

struct AlbumView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let album: Album
    
    @State var tracks = [Track]()
    @State var imageColors = ImageColors()
    @State var toolbarBackgroundVisible = false
    
    var body: some View {
        List {
            Header(album: album, imageColors: imageColors, toolbarBackgroundVisible: $toolbarBackgroundVisible) { shuffle in
                AudioPlayer.current.startPlayback(tracks: tracks.sorted { $0.index < $1.index }, startIndex: 0, shuffle: shuffle, playbackInfo: .init(container: album))
            }
            .padding(.bottom, 5)
            
            TrackList(tracks: tracks, container: album, hideButtons: true)
                .padding(.horizontal, 20)
            
            if let overview = album.overview, overview.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                Text(overview)
            }
            
            VStack(alignment: .leading) {
                if let releaseDate = album.releaseDate {
                    Text(releaseDate, style: .date)
                }
                
                Text(tracks.reduce(0, { $0 + $1.runtime }).formatDuration())
            }
            .font(.subheadline)
            .listRowSeparator(.hidden)
            .foregroundStyle(.secondary)
            
            AdditionalAlbums(album: album)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        // introspect does not work here
        .modifier(
            ToolbarModifier(album: album, imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible) { next in
                AudioPlayer.current.queueTracks(
                    tracks.sorted { $0.index < $1.index },
                    index: next ? 0 : AudioPlayer.current.queue.count,
                    playbackInfo: .init(container: album, queueLocation: next ? .now : .later))
            }
        )
        .modifier(NowPlayingBarSafeAreaModifier())
        .userActivity("io.rfk.ampfin.album") {
            $0.title = album.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = album.id
            $0.targetContentIdentifier = "album:\(album.id)"
            $0.userInfo = [
                "albumId": album.id
            ]
            $0.webpageURL = JellyfinClient.shared.serverUrl.appending(path: "web").appending(path: "#").appending(path: "details").appending(queryItems: [
                .init(name: "id", value: album.id),
            ])
        }
        .task {
            if let tracks = try? await dataProvider.getTracks(albumId: album.id) {
                self.tracks = tracks
            }
        }
        .onAppear {
            Task.detached {
                if let imageColors = await ImageColors.getImageColors(cover: album.cover) {
                    withAnimation {
                        self.imageColors = imageColors
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AlbumView(album: Album.fixture, tracks: [
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
            Track.fixture,
        ])
    }
}
