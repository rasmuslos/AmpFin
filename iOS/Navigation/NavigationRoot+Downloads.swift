//
//  Navigation+Artists.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import MusicKit

extension NavigationRoot {
    struct DownloadsTab: View {
        @State var navigationPath = NavigationPath()
        
        var body: some View {
            NavigationStack(path: $navigationPath) {
                LibraryView()
                    .navigationDestination(for: AlbumLoadDestination.self) { data in
                        AlbumLoadView(albumId: data.albumId)
                    }
            }
            .environment(\.libraryDataProvider, OfflineLibraryDataProvider())
            .modifier(NowPlayingBarModifier())
            .onReceive(NotificationCenter.default.publisher(for: NavigationRoot.navigateNotification)) { notification in
                if let albumId = notification.userInfo?["albumId"] as? String {
                    navigationPath.append(AlbumLoadDestination(albumId: albumId))
                }
            }
            .tabItem {
                Label("tab.downloads", systemImage: "arrow.down")
            }
        }
    }
}
