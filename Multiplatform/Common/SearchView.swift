//
//  SearchView.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI
import Defaults
import AmpFinKit
import AFPlayback

internal struct SearchView: View {
    @Binding var search: String
    @Binding var searchTab: Tab
    @Binding var selected: Bool
    
    @State private var task: Task<(), Never>? = nil
    
    @State private var tracks = [Track]()
    @State private var albums = [Album]()
    @State private var artists = [Artist]()
    @State private var playlists = [Playlist]()
    
    var body: some View {
        List {
            Picker("search.library", selection: $searchTab) {
                Text("search.jellyfin")
                    .tag(Tab.online)
                Text("search.downloaded")
                    .tag(Tab.offline)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
            
            if !artists.isEmpty {
                Section("section.artists") {
                    ArtistList(artists: artists)
                        .padding(.horizontal, 20)
                }
            }
            
            if !albums.isEmpty {
                Section("section.albums") {
                    ForEach(albums) { album in
                        NavigationLink(value: album) {
                            AlbumListRow(album: album)
                        }
                        .listRowInsets(.init(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                }
            }
            
            if !playlists.isEmpty {
                Section("section.playlists") {
                    ForEach(playlists) { playlist in
                        NavigationLink(value: playlist) {
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
                            AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init(container: nil, search: search))
                        }
                        .listRowInsets(.init(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("title.search")
        .searchable(text: $search, isPresented: $selected, placement: .navigationBarDrawer(displayMode: .always), prompt: "search.placeholder")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .modifier(NowPlaying.SafeAreaModifier())
        .task(id: searchTab) {
            fetchSearchResults(shouldReset: true)
        }
        .refreshable {
            fetchSearchResults(shouldReset: true)
        }
        .onChange(of: search) {
            fetchSearchResults(shouldReset: false)
        }
        .modifier(AccountToolbarButtonModifier(requiredSize: .compact))
    }
    
    private func fetchSearchResults(shouldReset: Bool) {
        let search = search.lowercased()
        
        if shouldReset {
            tracks = []
            albums = []
            artists = []
            playlists = []
        }
        
        task?.cancel()
        task = Task.detached(priority: .userInitiated) { [search] in
            async let tracks = searchTab.dataProvider.tracks(limit: 20, startIndex: 0, sortOrder: .lastPlayed, ascending: false, favoriteOnly: false, search: search).0
            async let albums = searchTab.dataProvider.albums(limit: 20, startIndex: 0, sortOrder: .lastPlayed, ascending: false, search: search).0
            async let artists = searchTab.dataProvider.artists(limit: 20, startIndex: 0, albumOnly: false, search: search).0
            async let playlists = searchTab.dataProvider.playlists(search: search)
            
            try? await MainActor.run { [tracks, albums, artists, playlists] in
                guard !Task.isCancelled else {
                    return
                }
                
                self.tracks = Array(tracks.prefix(20))
                self.albums = Array(albums.prefix(20))
                self.artists = Array(artists.prefix(20))
                self.playlists = Array(playlists.prefix(20))
            }
        }
    }
}

internal extension SearchView {
    enum Tab: Codable, _DefaultsSerializable {
        case online
        case offline
    }
}
internal extension SearchView.Tab {
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
    SearchView(search: .constant("Hello, World!"), searchTab: .constant(.online), selected: .constant(true))
}
