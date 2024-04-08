//
//  AlbumsView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import Defaults
import AFBase

struct AlbumsView: View {
    @Default(.sortOrder) private var sortOrder
    @Default(.sortAscending) private var sortAscending
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State private var count = 0
    @State private var albums = [Album]()
    @State private var failed = false
    
    @State private var search: String = ""
    
    var sortState: [String] {[
        sortOrder.rawValue,
        sortAscending.description,
    ]}
    
    var body: some View {
        VStack {
            if !albums.isEmpty {
                ScrollView {
                    AlbumGrid(albums: filter(), count: count, loadMore: fetchAlbums)
                        .padding()
                }
            } else if failed {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.albums")
        .searchable(text: $search, placement: .navigationBarDrawer, prompt: "search.albums")
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            SortSelector(ascending: $sortAscending, sortOrder: $sortOrder)
        }
        .task {
            await fetchAlbums()
        }
        .refreshable {
            albums = []
            await fetchAlbums()
        }
        .onChange(of: sortState) {
            Task {
                albums = []
                await fetchAlbums()
            }
        }
    }
}

// MARK: Helper

private extension AlbumsView {
    func fetchAlbums() async {
        failed = false
        
        do {
            let result = try await dataProvider.getAlbums(limit: 100, startIndex: albums.count, sortOrder: sortOrder, ascending: sortAscending)
            
            count = result.1
            albums += result.0
        } catch {
            failed = true
        }
    }
    
    func filter() -> [Album] {
        if search == "" {
            return albums
        } else {
            return albums.filter { $0.name.lowercased().contains(search.lowercased()) }
        }
    }
}

#Preview {
    NavigationStack {
        AlbumsView()
    }
}
