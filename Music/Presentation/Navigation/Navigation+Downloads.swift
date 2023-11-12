//
//  Navigation+Artists.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

extension NavigationRoot {
    struct DownloadsTab: View {
        var body: some View {
            NavigationStack {
                LibraryView()
            }
            .environment(\.libraryDataProvider, OfflineLibraryDataProvider())
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.downloads", systemImage: "arrow.down")
            }
        }
    }
}
