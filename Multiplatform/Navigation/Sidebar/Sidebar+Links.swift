//
//  Sidebar+Section.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 08.04.24.
//

import SwiftUI
import Defaults
import AFBase
import AFOffline

extension Sidebar {
    struct LibraryLinks: View {
        @Default private var expanded: Bool
        
        let provider: DataProvider
        
        init(provider: DataProvider) {
            self.provider = provider
            _expanded = Default(.providerExpanded(provider))
        }
        
        var body: some View {
            Section(provider.title, isExpanded: $expanded) {
                ForEach(provider.panels, id: \.hashValue) { panel in
                    NavigationLink(value: Selection(provider: provider, panel: panel)) {
                        Label(panel.title!, systemImage: panel.icon!)
                    }
                }
            }
        }
    }
    
    struct PlaylistLinks: View {
        @Default(.playlistSectionExpanded) private var playlistSectionExpanded
        
        var provider: DataProvider?
        
        @State private var playlists = [Playlist]()
        
        var body: some View {
            if !playlists.isEmpty {
                Section("section.playlists", isExpanded: $playlistSectionExpanded) {
                    ForEach(playlists) { playlist in
                        NavigationLink(value: Selection(
                            provider: provider ?? (OfflineManager.shared.isPlaylistDownloaded(playlistId: playlist.id) ? .offline : .online),
                            panel: .playlist(id: playlist.id))) {
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
        
        private func fetchPlaylists() async {
            if let playlists = try? await provider?.libraryProvider.getPlaylists() {
                self.playlists = playlists
            } else if let playlists = try? await OnlineLibraryDataProvider().getPlaylists() {
                self.playlists = playlists
            } else if let playlists = try? await OfflineLibraryDataProvider().getPlaylists() {
                self.playlists = playlists
            }
        }
    }
}
