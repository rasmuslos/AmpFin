//
//  NavigationRoot.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import CoreSpotlight

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
        .onChange(of: activeTab) {
            setLastActiveTab()
        }
        .onContinueUserActivity(CSSearchableItemActionType, perform: { userActivity in
            print(userActivity)
        })
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
