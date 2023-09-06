//
//  NavigationRoot.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct NavigationRoot: View {
    var body: some View {
        TabView {
            LibraryTab()
            DownloadsTab()
            SearchTab()
        }
    }
}

#Preview {
    NavigationRoot()
}
