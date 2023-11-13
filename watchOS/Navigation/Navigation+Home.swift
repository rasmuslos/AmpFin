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
                NavigationLink(value: LibraryNavigationDestination()) {
                    Label("section.library", systemImage: "rectangle.stack.fill")
                }
            }
        }
    }
}
