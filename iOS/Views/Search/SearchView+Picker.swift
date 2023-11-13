//
//  SearchView+Picker.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI

extension SearchView {
    struct ProviderPicker: View {
        @Binding var selection: Tab
        
        var body: some View {
            Picker("search.library", selection: $selection) {
                Text("search.jellyfin", comment: "Search the Jellyfin server")
                    .tag(Tab.online)
                Text("search.downloaded", comment: "Search the downloaded content")
                    .tag(Tab.offline)
            }
            .pickerStyle(SegmentedPickerStyle())
            .listRowSeparator(.hidden)
        }
    }
}

// MARK: Helper

extension SearchView {
    enum Tab {
    case online
    case offline
    }
}
