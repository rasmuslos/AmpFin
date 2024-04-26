//
//  NavigationRoot+Home.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase

extension TabBarView {
    struct LibraryTab: View {
        @State var navigationPath = NavigationPath()
        
        var body: some View {
            NavigationStack(path: $navigationPath) {
                LibraryView()
                    .navigationDestination(for: Navigation.AlbumLoadDestination.self) { data in
                        AlbumLoadView(albumId: data.albumId)
                    }
                    .navigationDestination(for: Navigation.ArtistLoadDestination.self) { data in
                        ArtistLoadView(artistId: data.artistId)
                    }
                    .navigationDestination(for: Navigation.PlaylistLoadDestination.self) { data in
                        PlaylistLoadView(playlistId: data.playlistId)
                    }
            }
            .environment(\.libraryDataProvider, OnlineLibraryDataProvider())
            .modifier(CompactNowPlayingBarModifier())
            .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateNotification)) { notification in
                if let albumId = notification.userInfo?["albumId"] as? String {
                    navigationPath.append(Navigation.AlbumLoadDestination(albumId: albumId))
                } else if let artistId = notification.userInfo?["artistId"] as? String {
                    navigationPath.append(Navigation.ArtistLoadDestination(artistId: artistId))
                } else if let playlistId = notification.userInfo?["playlistId"] as? String {
                    navigationPath.append(Navigation.PlaylistLoadDestination(playlistId: playlistId))
                }
            }
            .tabItem {
                Label("tab.libarary", systemImage: "rectangle.stack.fill")
            }
        }
    }
}
