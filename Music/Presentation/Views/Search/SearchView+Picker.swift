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
            Picker("Library", selection: $selection) {
                Text("Jellyfin")
                    .tag(Tab.online)
                Text("Downloaded")
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
