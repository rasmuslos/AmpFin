//
//  LibraryView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import MusicKit

struct LibraryView: View {
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    @Environment(\.libraryDataProvider) var dataProvider
    @Environment(\.libraryOnline) var online
    
    @State var recentAlbums: [Album]?
    
    var body: some View {
        ScrollView {
            List {
                Links()
            }
            .listStyle(.plain)
            .navigationTitle("title.library")
            .frame(height: CGFloat(Links.count) * minRowHeight)
            
            if let recentAlbums = recentAlbums, recentAlbums.count > 0 {
                HStack {
                    Text("home.recentlyAdded", comment: "Albums recently added to the Jellyfin server")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                AlbumGrid(albums: recentAlbums)
                    .padding(.horizontal)
            } else if !online && dataProvider as? OnlineLibraryDataProvider != nil {
                ContentUnavailableView("offline.title", systemImage: "network.slash", description: Text("offline.description"))
                    .padding(.top, 100)
            }
            
            Spacer()
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .onAppear(perform: loadRecentAlbums)
        .refreshable(action: loadRecentAlbums)
    }
}

// MARK: Helper

extension LibraryView {
    @Sendable
    func loadRecentAlbums() {
        Task.detached {
            recentAlbums = try? await dataProvider.getRecentAlbums()
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
