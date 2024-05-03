//
//  SplitView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 08.04.24.
//

import Foundation
import Defaults
import SwiftUI
import AFOffline

struct Sidebar: View {
    @Default(.lastSidebarSelection) private var selection
    
    var provider: DataProvider?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if let provider = provider {
                    LibraryLinks(provider: provider)
                } else {
                    ForEach(DataProvider.allCases, id: \.hashValue) {
                        LibraryLinks(provider: $0)
                    }
                }
                
                PlaylistLinks(provider: provider)
            }
            .modifier(AccountToolbarButtonModifier(requiredSize: nil))
            .modifier(NowPlaying.LeadingOffsetModifier())
            .toolbar {
                if provider == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            selection = .init(provider: nil, panel: .search)
                        } label: {
                            Label("search", systemImage: "magnifyingglass")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
        } detail: {
            if let selection = selection {
                NavigationStack {
                    selection.panel.content
                        .id(selection.panel)
                        .id(selection.provider)
                }
            } else {
                ProgressView()
                    .onAppear {
                        selection = .init(provider: .online, panel: .tracks)
                    }
            }
        }
        .environment(\.libraryDataProvider, selection?.provider?.libraryProvider ?? MockLibraryDataProvider())
        .modifier(NowPlayingBarModifier(visible: provider == nil))
        .modifier(Navigation.NotificationModifier(
            navigateAlbum: {
                selection = .init(provider: .online, panel: .artist(id: $0))
            }, navigateArtist: {
                if OfflineManager.shared.isAlbumDownloaded(albumId: $0) {
                    selection = .init(provider: .offline, panel: .album(id: $0))
                } else {
                    selection = .init(provider: .online, panel: .album(id: $0))
                }
            }, navigatePlaylist: {
                if OfflineManager.shared.isAlbumDownloaded(albumId: $0) {
                    selection = .init(provider: .offline, panel: .album(id: $0))
                } else {
                    selection = .init(provider: .online, panel: .album(id: $0))
                }
            }))
    }
}

private extension Sidebar {
    struct NowPlayingBarModifier: ViewModifier {
        let visible: Bool
        
        func body(content: Content) -> some View {
            if visible {
                content
                    .modifier(NowPlaying.RegularBarModifier())
            } else {
                content
            }
        }
    }
}

#Preview {
    Sidebar()
}
