//
//  XRTabs.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 03.05.24.
//

import SwiftUI
import Defaults

struct XRTabs: View {
    @Default(.searchTab) private var searchTab
    
    var body: some View {
        TabView {
            Sidebar(provider: .online)
                .tabItem {
                    Label("tab.libarary", systemImage: "rectangle.stack.fill")
                }
            
            Sidebar(provider: .offline)
                .tabItem {
                    Label("tab.downloads", systemImage: "arrow.down")
                }
            
            NavigationStack {
                SearchView(searchTab: $searchTab)
            }
            .environment(\.libraryDataProvider, searchTab.dataProvider)
            .tabItem {
                Label("tab.search", systemImage: "magnifyingglass")
            }
        }
    }
}

#Preview {
    XRTabs()
}
