//
//  NavigationRoot.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import CoreSpotlight
import MusicKit

struct NavigationRoot: View {
    @State var activeTab: Tab = Self.getLastActiveTab()
    
    var body: some View {
        TabView(selection: $activeTab) {
            LibraryTab()
                .tag(Tab.library)
            DownloadsTab()
                .tag(Tab.downloads)
            SearchTab()
                .tag(Tab.search)
        }
        .onReceive(NotificationCenter.default.publisher(for: Self.navigateArtistNotification)) { notification in
            if let id = notification.object as? String {
                withAnimation {
                    activeTab = .library
                }
                
                NotificationCenter.default.post(name: Self.navigateNotification, object: nil, userInfo: [
                    "artistId": id,
                ])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Self.navigateAlbumNotification)) { notification in
            if let id = notification.object as? String {
                if OfflineManager.shared.getAlbum(albumId: id) != nil {
                    activeTab = .downloads
                } else {
                    activeTab = .library
                }
                
                NotificationCenter.default.post(name: Self.navigateNotification, object: nil, userInfo: [
                    "albumId": id,
                ])
            }
        }
        .onChange(of: activeTab) {
            setLastActiveTab()
        }
    }
}

// MARK: Helper

extension NavigationRoot {
    enum Tab: Int {
        case library = 0
        case downloads = 1
        case search = 2
    }
    
    private static func getLastActiveTab() -> Tab {
        let value = UserDefaults.standard.integer(forKey: "lastActiveTab")
        return Tab(rawValue: value) ?? .library
    }
    func setLastActiveTab() {
        UserDefaults.standard.set(activeTab.rawValue, forKey: "lastActiveTab")
    }
}

#Preview {
    NavigationRoot()
}
