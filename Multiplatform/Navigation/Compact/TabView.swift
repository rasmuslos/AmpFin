//
//  NavigationRoot.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import Defaults
import AFBase
import AFOffline

struct TabBarView: View {
    @Default(.lastActiveTab) private var activeTab
    
    var body: some View {
        TabView(selection: $activeTab) {
            LibraryTab()
                .tag(Tab.library)
            DownloadsTab()
                .tag(Tab.downloads)
            SearchTab()
                .tag(Tab.search)
        }
        .modifier(NowPlayingViewModifier())
        .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateArtistNotification)) { notification in
            if let id = notification.object as? String {
                withAnimation {
                    activeTab = .library
                }
                
                NotificationCenter.default.post(name: Navigation.navigateNotification, object: nil, userInfo: [
                    "artistId": id,
                ])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAlbumNotification)) { notification in
            if let id = notification.object as? String {
                if OfflineManager.shared.isAlbumDownloaded(albumId: id) {
                    withAnimation {
                        activeTab = .downloads
                    }
                    
                    NotificationCenter.default.post(name: Navigation.navigateNotification, object: nil, userInfo: [
                        "offlineAlbumId": id,
                    ])
                } else {
                    withAnimation {
                        activeTab = .library
                    }
                    
                    NotificationCenter.default.post(name: Navigation.navigateNotification, object: nil, userInfo: [
                        "albumId": id,
                    ])
                }
            }
        }
    }
}

private extension Defaults.Keys {
    static let lastActiveTab = Key("lastActiveTab", default: Tab.library)
}

private enum Tab: Int, _DefaultsSerializable {
    case library = 0
    case downloads = 1
    case search = 2
}

#Preview {
    TabBarView()
}
