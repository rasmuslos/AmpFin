//
//  SearchView.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI
import AFBase
import AFPlayback

struct SearchView: View {
    @State var query = ""
    @State var task: Task<(), Never>? = nil
    
    @State var tracks = [Track]()
    @State var albums = [Album]()
    @State var artists = [Artist]()
    @State var playlists = [Playlist]()
    
    @State var library: Tab = UserDefaults.standard.bool(forKey: "searchOnline") ? .online : .offline
    @State var dataProvider: LibraryDataProvider = UserDefaults.standard.bool(forKey: "searchOnline") ? OnlineLibraryDataProvider() : OfflineLibraryDataProvider()
    
    var body: some View {
        NavigationStack {
            List {
                ProviderPicker(selection: $library)
                
                if !tracks.isEmpty {
                    Section("section.tracks") {
                        ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                            TrackListRow(track: track) {
                                AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init(type: .tracks, query: query, container: nil))
                            }
                            .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .padding(.horizontal)
                        }
                    }
                }
                
                if !albums.isEmpty {
                    Section("section.albums") {
                        ForEach(albums) { album in
                            NavigationLink(destination: AlbumView(album: album)) {
                                AlbumListRow(album: album)
                            }
                            .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .padding(.horizontal)
                        }
                    }
                }
                
                if !artists.isEmpty {
                    Section("section.artists") {
                        ForEach(artists) { artist in
                            ArtistListRow(artist: artist)
                            .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .padding(.horizontal)
                        }
                    }
                }
                
                if !playlists.isEmpty {
                    Section("section.playlists") {
                        ForEach(playlists) { playlist in
                            NavigationLink(destination: PlaylistView(playlist: playlist)) {
                                PlaylistListRow(playlist: playlist)
                            }
                            .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("title.search")
            .modifier(NowPlayingBarSafeAreaModifier())
            .modifier(AccountToolbarButtonModifier())
            // Query
            .searchable(text: $query, prompt: "search.placeholder")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onChange(of: query) {
                fetchSearchResults()
            }
            // Online / Offline
            .onChange(of: library) {
                UserDefaults.standard.set(library == .online, forKey: "searchOnline")
                
                task?.cancel()
                
                tracks = []
                albums = []
                playlists = []
                
                switch library {
                case .online:
                    dataProvider = OnlineLibraryDataProvider()
                case .offline:
                    dataProvider = OfflineLibraryDataProvider()
                }
                
                fetchSearchResults()
            }
            .onAppear(perform: fetchSearchResults)
        }
        .environment(\.libraryDataProvider, dataProvider)
    }
}

extension SearchView {
    private func fetchSearchResults() {
        task?.cancel()
        task = Task.detached {
            // I guess this runs in parallel?
            (tracks, albums, artists, playlists) = (try? await (
                dataProvider.searchTracks(query: query.lowercased()),
                dataProvider.searchAlbums(query: query.lowercased()),
                dataProvider.searchArtists(query: query.lowercased()),
                dataProvider.searchPlaylists(query: query.lowercased())
            )) ?? ([], [], [], [])
        }
    }
}

#Preview {
    SearchView()
}
