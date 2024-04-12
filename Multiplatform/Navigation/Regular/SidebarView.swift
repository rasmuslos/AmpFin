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

struct SidebarView: View {
    @Default(.lastSidebarSelection) private var selection
    @State var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(DataProvider.allCases, id: \.hashValue) {
                    ProviderSection(provider: $0)
                }
                
                PlaylistSection()
            }
            .modifier(AccountToolbarButtonModifier(requiredSize: nil))
            .modifier(NowPlayingBarLeadingOffsetModifier())
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
                NavigationStack(path: $navigationPath) {
                    selection.section.content
                        .navigationDestination(for: Navigation.AlbumLoadDestination.self) { data in
                            switch data.provider {
                                case .online:
                                    AlbumLoadView(albumId: data.albumId, dataProviderOverride: OnlineLibraryDataProvider())
                                case .offline:
                                    AlbumLoadView(albumId: data.albumId, dataProviderOverride: OfflineLibraryDataProvider())
                                default:
                                    AlbumLoadView(albumId: data.albumId)
                            }
                        }
                        .navigationDestination(for: Navigation.ArtistLoadDestination.self) { data in
                            ArtistLoadView(artistId: data.artistId)
                        }
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
        .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateArtistNotification)) { notification in
            if let id = notification.object as? String {
                navigationPath.append(Navigation.ArtistLoadDestination(artistId: id))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAlbumNotification)) { notification in
            if let id = notification.object as? String {
                navigationPath.append(Navigation.AlbumLoadDestination(albumId: id, provider: .offline))
            }
        }
    }
}

private extension Defaults.Keys {
    static let lastSidebarSelection = Key<SidebarView.Selection?>("lastSidebarSelection")
}

#Preview {
    SidebarView()
}
