//
//  AlbumView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import SwiftUIIntrospect

struct AlbumView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let album: AlbumItem
    
    @State var songs = [SongItem]()
    @State var navbarVisible = false
    @State var imageColors = ImageColors()
    
    var body: some View {
        List {
            Header(album: album, navbarVisible: $navbarVisible, imageColors: $imageColors) { shuffle in
                AudioPlayer.shared.startPlayback(items: songs, startIndex: 0, shuffle: shuffle)
            }
            .navigationTitle(album.name)
            .navigationBarTitleDisplayMode(.inline)
            
            SongList(songs: songs, album: album)
                .padding(.top, 4)
            
            if let overview = album.overview {
                Text(overview)
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        // introspect does not work here
        .modifier(ToolbarModifier(album: album, navbarVisible: $navbarVisible, imageColors: $imageColors))
        .modifier(NowPlayingBarSafeAreaModifier())
        .task {
            if let songs = try? await dataProvider.getAlbumItems(id: album.id) {
                self.songs = songs
            }
        }
        .onAppear {
            Task.detached {
                if let imageColors = await getImageColors() {
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
        AlbumView(album: AlbumItem.fixture, songs: [
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
            SongItem.fixture,
        ])
    }
}
