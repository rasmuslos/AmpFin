//
//  NavigationRoot.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct NavigationRoot: View {
    @State var online = JellyfinClient.shared.isOnline
    
    var body: some View {
        TabView {
            LibraryTab()
            DownloadsTab()
            SearchTab()
        }
        .environment(\.libraryOnline, online)
        .onReceive(NotificationCenter.default.publisher(for: JellyfinClient.onlineStatusChanged), perform: { _ in
            online = JellyfinClient.shared.isOnline
        })
    }
}

#Preview {
    NavigationRoot()
}
