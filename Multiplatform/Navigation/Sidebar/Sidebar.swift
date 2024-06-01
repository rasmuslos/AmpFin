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

internal struct Sidebar: View {
    @Default(.sidebarSelection) private var sidebarSelection

    var provider: DataProvider?

    var body: some View {
        NavigationSplitView {
            List(selection: $sidebarSelection) {
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
                            sidebarSelection = .init(provider: nil, panel: .search)
                        } label: {
                            Label("search", systemImage: "magnifyingglass")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
        } detail: {
            if let sidebarSelection = sidebarSelection {
                NavigationStack {
                    sidebarSelection.panel.content
                        .id(sidebarSelection.panel)
                        .id(sidebarSelection.provider)
                }
            } else {
                ProgressView()
                    .onAppear {
                        sidebarSelection = .init(provider: .online, panel: .tracks)
                    }
            }
        }
        .environment(\.libraryDataProvider, sidebarSelection?.provider?.libraryProvider ?? MockLibraryDataProvider())
        .modifier(NowPlayingBarModifier(visible: provider == nil))
        .modifier(Navigation.NotificationModifier(
            navigateAlbum: {
                if OfflineManager.shared.offlineStatus(albumId: $0) == .downloaded {
                    sidebarSelection = .init(provider: .offline, panel: .album(id: $0))
                } else {
                    sidebarSelection = .init(provider: .online, panel: .album(id: $0))
                }
            }, navigateArtist: {
                sidebarSelection = .init(provider: .online, panel: .artist(id: $0))
            }, navigatePlaylist: {
                if OfflineManager.shared.offlineStatus(playlistId: $0) == .downloaded {
                    sidebarSelection = .init(provider: .offline, panel: .playlist(id: $0))
                } else {
                    sidebarSelection = .init(provider: .online, panel: .playlist(id: $0))
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
