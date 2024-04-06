//
//  LibraryView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase
import AFPlayback

struct LibraryView: View {
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    @Environment(\.libraryDataProvider) var dataProvider
    @Environment(\.libraryOnline) var online
#if targetEnvironment(macCatalyst)
    @Environment(NowPlayingViewState.self) private var viewState
#endif
    
    @State var albums: [Album]?
    @State var randomAlbums = UserDefaults.standard.bool(forKey: "libraryRandomAlbums")
    
    var body: some View {
        ScrollView {
            List {
                Links()
            }
            .listStyle(.plain)
            .navigationTitle("title.library")
#if targetEnvironment(macCatalyst)
            .toolbar(viewState.presented ? .hidden : .automatic, 
                     for: .navigationBar)
#endif
            .frame(height: CGFloat(Links.count) * minRowHeight)
            
            if let albums = albums, albums.count > 0 {
                HStack {
                    Text(randomAlbums ? "home.randomAlbums" : "home.recentlyAdded")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                AlbumsGrid(albums: albums)
                    .padding(.horizontal)
            } else if !online && dataProvider as? OnlineLibraryDataProvider != nil {
                ContentUnavailableView("offline.title", systemImage: "network.slash", description: Text("offline.description"))
                    .padding(.top, 100)
            }
            
            Spacer()
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .task {
            if !randomAlbums || albums == nil || albums?.isEmpty == true {
                await loadAlbums()
            }
        }
        .refreshable { await loadAlbums() }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            if randomAlbums != UserDefaults.standard.bool(forKey: "libraryRandomAlbums") {
                randomAlbums.toggle()
                
                Task.detached {
                    await loadAlbums()
                }
            }
        }
    }
}

// MARK: Helper

extension LibraryView {
    func loadAlbums() async {
        if randomAlbums {
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
