//
//  SearchView+Picker.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI

extension SearchView {
    struct PickerModifier: ViewModifier {
        @Binding var selection: Tab
        
        func body(content: Content) -> some View {
            content.safeAreaInset(edge: .top) {
                Picker("Library", selection: $selection) {
                    Text("Jellyfin")
                        .tag(Tab.online)
                    Text("Downloaded")
                        .tag(Tab.offline)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(.ultraThickMaterial)
            }
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
