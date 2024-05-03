//
//  LibraryView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import Defaults
import AFBase
import AFPlayback

struct LibraryView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    @Environment(\.defaultMinListRowHeight) private var minRowHeight
    
    @Default(.libraryRandomAlbums) private var libraryRandomAlbums
    
    @State private var albums: [Album]?
    
    var body: some View {
        ScrollView {
            List {
                Group {
                    NavigationLink(destination: TracksView(favoritesOnly: false)) {
                        Label("title.tracks", systemImage: "music.note")
                    }
                    NavigationLink(destination: AlbumsView()) {
                        Label("title.albums", systemImage: "square.stack")
                    }
                    
                    NavigationLink(destination: PlaylistsView()) {
                        Label("title.playlists", systemImage: "music.note.list")
                    }
                    
                    NavigationLink(destination: TracksView(favoritesOnly: true)) {
                        Label("title.favorites", systemImage: "heart")
                    }
                    
                    // MARK: Artists
                    
                    NavigationLink(destination: ArtistsView(albumOnly: true)) {
                        Label("title.albumArtists", systemImage: "music.mic")
                    }
                    .disabled(!dataProvider.supportsArtistLookup)
                    NavigationLink(destination: ArtistsView(albumOnly: false)) {
                        Label("title.artists", systemImage: "mic.fill")
                    }
                    .disabled(!dataProvider.supportsArtistLookup)
                }
                .font(.headline)
            }
            .listStyle(.plain)
            .frame(height: 6 * minRowHeight)
            
            if let albums = albums, albums.count > 0 {
                HStack {
                    Text(libraryRandomAlbums ? "home.randomAlbums" : "home.recentlyAdded")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
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
            if !libraryRandomAlbums || albums == nil || albums?.isEmpty == true {
                await loadAlbums()
            }
        }
        .refreshable { await loadAlbums() }
    }
    
    private func loadAlbums() async {
        if libraryRandomAlbums {
            albums = try? await dataProvider.getRandomAlbums()
        } else {
            albums = try? await dataProvider.getRecentAlbums()
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
