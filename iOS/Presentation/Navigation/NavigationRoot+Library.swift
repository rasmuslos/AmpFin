//
//  NavigationRoot+Home.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase

extension NavigationRoot {
    struct LibraryTab: View {
        @State var navigationPath = NavigationPath()
        
        var body: some View {
            NavigationStack(path: $navigationPath) {
                LibraryView()
                    .navigationDestination(for: AlbumLoadDestination.self) { data in
                        AlbumLoadView(albumId: data.albumId)
                    }
                    .navigationDestination(for: ArtistLoadDestination.self) { data in
                        ArtistLoadView(artistId: data.artistId)
                    }
            }
            .environment(\.libraryDataProvider, OnlineLibraryDataProvider())
            .onReceive(NotificationCenter.default.publisher(for: NavigationRoot.navigateNotification)) { notification in
                if let albumId = notification.userInfo?["albumId"] as? String {
                    navigationPath.append(AlbumLoadDestination(albumId: albumId))
                } else if let artistId = notification.userInfo?["artistId"] as? String {
                    navigationPath.append(ArtistLoadDestination(artistId: artistId))
                }
            }
            .tabItem {
                Label("tab.libarary", systemImage: "rectangle.stack.fill")
            }
        }
    }
}
