//
//  NavigationRoot+ListenNow.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import Foundation
import SwiftUI
import AFBase

extension NavigationRoot {
    struct ListenNowView: View {
        @State var recentAlbums = [Album]()
        @State var randomAlbums = [Album]()
        @State var newAlbums = [Album]()
        @State var favoriteAlbums = [Album]()
        
        @State var randomPlaylists = [Playlist]()
        @State var newPlaylists = [Playlist]()
        @State var favoritePlaylists = [Playlist]()
        
        var body: some View {
            NavigationStack {
                if recentAlbums.isEmpty && randomAlbums.isEmpty && newAlbums.isEmpty && favoriteAlbums.isEmpty
                    && randomPlaylists.isEmpty && newPlaylists.isEmpty && favoritePlaylists.isEmpty {
                    ProgressView()
                } else {
                    ScrollView {
                        if !newPlaylists.isEmpty {
                            RowTitle(title: String(localized: "row.new.playlists"))
                                .padding(.bottom, -45)
                            LargePlaylistRow(playlists: newPlaylists)
                        }
                        
                        if !recentAlbums.isEmpty {
                            AlbumsRowTitle(title: String(localized: "row.recent"), albums: recentAlbums)
                        }
                        
                        if !randomAlbums.isEmpty {
                            AlbumsRowTitle(title: String(localized: "row.random.albums"), albums: randomAlbums)
                        }
                        
                        if randomPlaylists.count > 4 {
                            PlaylistsRowTitle(title: String(localized: "row.random.playlists"), playlists: randomPlaylists)
                        }
                        
                        if !newAlbums.isEmpty {
                            AlbumsRowTitle(title: String(localized: "row.new.albums"), albums: newAlbums)
                        }
                        
                        if !favoriteAlbums.isEmpty {
                            AlbumsRowTitle(title: String(localized: "row.favorites.albums"), albums: favoriteAlbums)
                        }
                        
                        if !favoritePlaylists.isEmpty {
                            PlaylistsRowTitle(title: String(localized: "row.favorites.playlists"), playlists: favoritePlaylists)
                        }
                    }
                    .ignoresSafeArea(edges: .horizontal)
                }
            }
            .tabItem {
                Text("title.listenNow")
            }
            .onAppear(perform: fetchItems)
        }
    }
}

extension NavigationRoot.ListenNowView {
    func fetchItems() {
        Task.detached {
            (randomAlbums, newAlbums, favoriteAlbums) = (
                try await JellyfinClient.shared.getAlbums(limit: 30),
                try await JellyfinClient.shared.getAlbums(limit: 30, sortOrder: .added, ascending: false, favorite: false),
                try await JellyfinClient.shared.getAlbums(limit: 30, sortOrder: .plays, ascending: false, favorite: true)
            )
        }
        
        Task.detached {
            (randomPlaylists, newPlaylists, favoritePlaylists) = (
                try await JellyfinClient.shared.getPlaylists(limit: 30),
                try await JellyfinClient.shared.getPlaylists(limit: 30, sortOrder: .added, ascending: false, favorite: false),
                try await JellyfinClient.shared.getPlaylists(limit: 30, sortOrder: .plays, ascending: false, favorite: true)
            )
        }
        
        Task.detached {
            let recentTracks = try await JellyfinClient.shared.getTracks(limit: 40, sortOrder: .lastPlayed, ascending: false, favorite: false)
            var albumIds = Set<String>()
            
            for track in recentTracks {
                albumIds.insert(track.album.id)
            }
            
            recentAlbums = try await albumIds.parallelMap(JellyfinClient.shared.getAlbum)
        }
    }
}
