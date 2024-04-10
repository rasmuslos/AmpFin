//
//  SplitView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 08.04.24.
//

import Foundation
import Defaults
import SwiftUI

struct SidebarView: View {
    @Default(.lastSidebarSelection) private var selection
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(DataProvider.allCases, id: \.hashValue) {
                    ProviderSection(provider: $0)
                }
                
                PlaylistSection()
            }
            .modifier(AccountToolbarButtonModifier(requiredSize: nil))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selection = .init(provider: .online, section: .search)
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        } detail: {
            if let selection = selection {
                NavigationStack {
                    selection.section.content
                        .id(selection.section)
                        .id(selection.provider)
                }
            } else {
                ProgressView()
                    .onAppear {
                        selection = .init(provider: .online, section: .tracks)
                    }
            }
        }
        .modifier(RegularNowPlayingBarModifier())
        .environment(\.libraryDataProvider, selection?.provider.libraryProvider ?? MockLibraryDataProvider())
    }
}

private extension Defaults.Keys {
    static let lastSidebarSelection = Key<SidebarView.Selection?>("lastSidebarSelection")
}

#Preview {
    SidebarView()
}
