//
//  SearchView.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI
import Defaults
import AFBase
import AFPlayback

struct SearchView: View {
    @Default(.searchTab) private var searchTab
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var query = ""
    @State private var task: Task<(), Never>? = nil
    
    @State private var tracks = [Track]()
    @State private var albums = [Album]()
    @State private var artists = [Artist]()
    @State private var playlists = [Playlist]()
    
    var body: some View {
        NavigationStack {
            List {
                Picker("search.library", selection: $searchTab) {
                    Text("search.jellyfin", comment: "Search the Jellyfin server")
                        .tag(Tab.online)
                    Text("search.downloaded", comment: "Search the downloaded content")
                        .tag(Tab.offline)
                }
                .pickerStyle(SegmentedPickerStyle())
                .listRowSeparator(.hidden)
                
                if !artists.isEmpty {
                    Section("section.artists") {
                        ArtistList(artists: artists)
                            .padding(.horizontal, 20)
                    }
                }
                
                if !albums.isEmpty {
                    Section("section.albums") {
                        ForEach(albums) { album in
                            NavigationLink(destination: AlbumView(album: album)) {
                                AlbumListRow(album: album)
                            }
                            .listRowInsets(.init(top: 6, leading: 20, bottom: 6, trailing: 20))
                        }
                    }
                }
                
                if !playlists.isEmpty {
                    Section("section.playlists") {
                        ForEach(playlists) { playlist in
                            NavigationLink(destination: PlaylistView(playlist: playlist)) {
                                PlaylistListRow(playlist: playlist)
                            }
                            .listRowInsets(.init(top: 6, leading: 20, bottom: 6, trailing: 20))
                        }
                    }
                }
                
                if !tracks.isEmpty {
                    Section("section.tracks") {
                        ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                            TrackListRow(track: track) {
                                AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init(container: nil, search: query))
                            }
                            .listRowInsets(.init(top: 6, leading: 20, bottom: 6, trailing: 20))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("title.search")
            .modifier(NowPlaying.SafeAreaModifier())
            .modifier(AccountToolbarButtonModifier(requiredSize: .compact))
            // Query
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "search.placeholder")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onChange(of: query) {
                fetchSearchResults()
            }
            // Online / Offline
            .onChange(of: searchTab) {
                task?.cancel()
                
                tracks = []
                albums = []
                artists = []
                playlists = []
                
                fetchSearchResults()
            }
            .onAppear(perform: fetchSearchResults)
        }
        .environment(\.libraryDataProvider, searchTab.dataProvider)
    }
    
    private func fetchSearchResults() {
        task?.cancel()
        task = Task.detached {
            // I guess this runs in parallel?
            await (tracks, albums, artists, playlists) = (try? await (
                searchTab.dataProvider.searchTracks(query: query.lowercased()),
                searchTab.dataProvider.searchAlbums(query: query.lowercased()),
                searchTab.dataProvider.searchArtists(query: query.lowercased()),
                searchTab.dataProvider.searchPlaylists(query: query.lowercased()))
            ) ?? ([], [], [], [])
        }
    }
}

extension SearchView {
    enum Tab: Codable, _DefaultsSerializable {
        case online
        case offline
    }
}
extension SearchView.Tab {
    var dataProvider: LibraryDataProvider {
        switch self {
            case .online:
                OnlineLibraryDataProvider()
            case .offline:
                OfflineLibraryDataProvider()
        }
    }
}

#Preview {
    SearchView()
}
