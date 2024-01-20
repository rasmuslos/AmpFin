//
//  NavigationRoot.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI

struct NavigationRoot: View {
    @State var activeTab: Tab = Self.getLastActiveTab()
    
    var body: some View {
        TabView(selection: $activeTab) {
            ListenNowView()
                .tag(Tab.listenNow)
            AlbumsView()
                .tag(Tab.albums)
            PlaylistsView()
                .tag(Tab.playlists)
            TracksView()
                .tag(Tab.tracks)
            NowPlayingView()
                .tag(Tab.nowPlaying)
            SearchView()
                .tag(Tab.search)
        }
    }
}

extension NavigationRoot {
    enum Tab: Int {
        case listenNow = 0
        case albums = 1
        case playlists = 2
        case tracks = 3
        case nowPlaying = 4
        case search = 5
    }
    
    private static func getLastActiveTab() -> Tab {
        let value = UserDefaults.standard.integer(forKey: "lastActiveTab")
        return Tab(rawValue: value) ?? .listenNow
    }
    func setLastActiveTab() {
        UserDefaults.standard.set(activeTab.rawValue, forKey: "lastActiveTab")
    }
}

#Preview {
    NavigationRoot()
}
