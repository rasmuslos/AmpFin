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
            Header(album: album, navbarVisible: $navbarVisible, imageColors: $imageColors)
                .navigationTitle(album.name)
                .navigationBarTitleDisplayMode(.inline)
            
            SongList(songs: songs, includeButtons: false)
                .padding(.top, 4)
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .modifier(ToolbarModifier(album: album, navbarVisible: $navbarVisible, imageColors: $imageColors))
        // introspect does not work here
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
