//
//  NavigationRoot+Home.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

extension NavigationRoot {
    struct LibraryTab: View {
        var body: some View {
            NavigationStack {
                LibraryView()
            }
            .environment(\.libraryOnline, true)
            .environment(\.libraryDataProvider, OnlineLibraryDataProivder())
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("Library", systemImage: "rectangle.stack.fill")
            }
        }
    }
}
