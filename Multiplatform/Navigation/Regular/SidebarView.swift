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
                
                // :(
                Color.clear
                    .modifier(AccountToolbarButtonModifier())
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink(value: Selection(provider: .online, section: .search)) {
                                Image(systemName: "magnifyingglass")
                            }
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
        .navigationSplitViewColumnWidth(320)
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
