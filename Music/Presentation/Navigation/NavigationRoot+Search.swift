//
//  SearchTab.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

extension NavigationRoot {
    struct SearchTab: View {
        var body: some View {
            SearchView()
                .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("Serach", systemImage: "magnifyingglass")
            }
        }
    }
}
