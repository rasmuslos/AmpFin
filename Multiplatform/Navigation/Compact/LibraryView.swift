//
//  LibraryView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import Defaults
import AFBase
import AFPlayback

struct LibraryView: View {
    @Environment(\.libraryOnline) private var online
    @Environment(\.libraryDataProvider) private var dataProvider
    @Environment(\.defaultMinListRowHeight) private var minRowHeight
    
    @Default(.libraryRandomAlbums) private var libraryRandomAlbums
    
    @State private var albums: [Album]?
    
    var body: some View {
        ScrollView {
            List {
                Links()
            }
            .listStyle(.plain)
            .navigationTitle("title.library")
            .frame(height: CGFloat(Links.count) * minRowHeight)
            
            if let albums = albums, albums.count > 0 {
                HStack {
                    Text(libraryRandomAlbums ? "home.randomAlbums" : "home.recentlyAdded")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                AlbumGrid(albums: albums)
                    .padding(.horizontal, 20)
            } else if !online && dataProvider as? OnlineLibraryDataProvider != nil {
                ContentUnavailableView("offline.title", systemImage: "network.slash", description: Text("offline.description"))
                    .padding(.top, 100)
            }
            
            Spacer()
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .task {
            if !libraryRandomAlbums || albums == nil || albums?.isEmpty == true {
                await loadAlbums()
            }
        }
        .refreshable { await loadAlbums() }
    }
}

// MARK: Helper

extension LibraryView {
    func loadAlbums() async {
        if libraryRandomAlbums {
            albums = try? await dataProvider.getRandomAlbums()
        } else {
            albums = try? await dataProvider.getRecentAlbums()
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
