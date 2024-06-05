//
//  LibraryView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import Defaults
import AmpFinKit

struct LibraryView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    @Environment(\.defaultMinListRowHeight) private var minRowHeight
    
    @Default(.libraryRandomAlbums) private var libraryRandomAlbums
    
    @State private var albums = [Album]()
    
    var body: some View {
        ScrollView {
            List {
                Group {
                    NavigationLink(value: .tracksDestination(favoriteOnly: false)) {
                        Label("title.tracks", systemImage: "music.note")
                    }
                    NavigationLink(value: .albumsDestination) {
                        Label("title.albums", systemImage: "square.stack")
                    }
                    
                    NavigationLink(value: .playlistsDestination) {
                        Label("title.playlists", systemImage: "music.note.list")
                    }
                    
                    NavigationLink(value: .tracksDestination(favoriteOnly: true)) {
                        Label("title.favorites", systemImage: "star")
                    }
                    
                    NavigationLink(value: .artistsDestination(albumOnly: true)) {
                        Label("title.albumArtists", systemImage: "music.mic")
                    }
                    .disabled(!dataProvider.supportsArtistLookup)
                    NavigationLink(value: .artistsDestination(albumOnly: false)) {
                        Label("title.artists", systemImage: "mic.fill")
                    }
                    .disabled(!dataProvider.supportsArtistLookup)
                }
                .lineLimit(1)
            }
            .listStyle(.plain)
            .frame(height: 6 * minRowHeight)
            
            if !albums.isEmpty {
                HStack(spacing: 0) {
                    Text(libraryRandomAlbums ? "home.randomAlbums" : "home.recentlyAdded")
                        .font(.headline)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                AlbumGrid(albums: albums)
                    .padding(.horizontal, 20)
            } else if !JellyfinClient.shared.online && dataProvider as? OnlineLibraryDataProvider != nil {
                ContentUnavailableView("offline.title", systemImage: "network.slash", description: Text("offline.description"))
                    .padding(.top, 100)
            }
            
            Spacer()
        }
        .navigationTitle("title.library")
        .modifier(NowPlaying.SafeAreaModifier())
        .task {
            if !libraryRandomAlbums || albums.isEmpty == true {
                await loadAlbums()
            }
        }
        .refreshable { await loadAlbums() }
    }
    
    private func loadAlbums() async {
        let function = libraryRandomAlbums ? dataProvider.randomAlbums : dataProvider.recentAlbums
        
        guard let albums = try? await function() else {
            return
        }
        
        self.albums = albums
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
