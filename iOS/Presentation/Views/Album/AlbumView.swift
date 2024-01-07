//
//  AlbumView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBaseKit
import AFPlaybackKit

struct AlbumView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let album: Album
    let userActivity: NSUserActivity
    
    init(album: Album) {
        self.album = album
        userActivity = .createUserActivity(item: album)
    }
    
    #if DEBUG
    init(album: Album, tracks: [Track]) {
        self.init(album: album)
        self.tracks = tracks
    }
    #endif
    
    @State var tracks = [Track]()
    @State var toolbarBackgroundVisible = false
    @State var imageColors = ImageColors()
    
    var body: some View {
        List {
            Header(album: album, toolbarBackgroundVisible: $toolbarBackgroundVisible, imageColors: $imageColors) { shuffle in
                AudioPlayer.current.startPlayback(tracks: tracks.sorted { $0.index < $1.index }, startIndex: 0, shuffle: shuffle, playbackInfo: .init(container: album))
            }
            .navigationTitle(album.name)
            .navigationBarTitleDisplayMode(.inline)
            
            TrackList(tracks: tracks, album: album, hideButtons: true)
                .padding(.top, 4)
            
            if let overview = album.overview, overview.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                Text(overview)
            }
            
            AdditionalAlbums(album: album)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        // introspect does not work here
        .modifier(
            ToolbarModifier(album: album, queueTracks: { next in
                AudioPlayer.current.queueTracks(
                    tracks.sorted { $0.index < $1.index },
                    index: next ? 0 : AudioPlayer.current.queue.count)
            }, toolbarBackgroundVisible: $toolbarBackgroundVisible, imageColors: $imageColors)
        )
        .modifier(NowPlayingBarSafeAreaModifier())
        .task {
            if let tracks = try? await dataProvider.getAlbumTracks(id: album.id) {
                self.tracks = tracks
            }
        }
        .onAppear {
            userActivity.becomeCurrent()
            
            Task.detached {
                if let imageColors = await ImageColors.getImageColors(cover: album.cover) {
                    withAnimation {
                        self.imageColors = imageColors
                    }
                }
            }
        }
        .onDisappear {
            userActivity.resignCurrent()
        }
    }
}

#if DEBUG
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
#endif
