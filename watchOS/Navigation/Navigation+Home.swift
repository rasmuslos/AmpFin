//
//  NavigationHome.swift
//  watchOS
//
//  Created by Rasmus Krämer on 14.11.23.
//

import SwiftUI

extension NavigationRoot {
    struct Home: View {
        var body: some View {
            List {
                NavigationLink(value: ListenNowNavigationDestination()) {
                    Label("section.listenNow", systemImage: "rectangle.stack.fill")
                }
                
                NavigationLink(value: LibraryNavigationDestination()) {
                    Label("section.library", systemImage: "rectangle.stack.fill")
                }
                NavigationLink(value: DownloadsNavigationDestination()) {
                    Label("section.downloads", systemImage: "rectangle.stack.fill")
                }
                
                NavigationLink(value: SearchNavigationDestination()) {
                    Label("section.search", systemImage: "rectangle.stack.fill")
                }
            }
            .navigationTitle("title.home")
            .modifier(NowPlayingModifier())
        }
    }
}
