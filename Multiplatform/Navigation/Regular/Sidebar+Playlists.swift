//
//  Sidebar+Playlists.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AFBase
import AFOffline
import Defaults

extension SidebarView {
    struct PlaylistSection: View {
        @Default(.playlistSectionExpanded) private var playlistSectionExpanded
        
        @State private var playlists = [Playlist]()
        
        var body: some View {
            if !playlists.isEmpty {
                Section("section.playlists", isExpanded: $playlistSectionExpanded) {
                    ForEach(playlists) { playlist in
                        NavigationLink(value: Selection(provider: OfflineManager.shared.isPlaylistDownloaded(playlistId: playlist.id) ? .offline : .online, section: .playlist(id: playlist.id))) {
                            HStack {
                                ItemImage(cover: playlist.cover)
                                    .frame(width: 40)
                                    .padding(.trailing, 3)
                                
                                Text(playlist.name)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            } else {
                Color.clear
                    .task { await fetchPlaylists() }
            }
        }
    }
}

extension SidebarView.PlaylistSection {
    private func fetchPlaylists() async {
        if let playlists = try? await OnlineLibraryDataProvider().getPlaylists() {
            self.playlists = playlists
        } else if let playlists = try? await OfflineLibraryDataProvider().getPlaylists() {
            self.playlists = playlists
        }
    }
}
