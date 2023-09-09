//
//  AlbumsView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct AlbumsView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var albums: [Album]?
    @State var errored = false
    
    @State var sortOrder = SortSelector.getSortOrder()
    @State var search: String = ""
    
    var body: some View {
        VStack {
            if albums != nil {
                ScrollView {
                    AlbumGrid(albums: filter())
                        .padding()
                }
            } else if errored {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Albums")
        .searchable(text: $search, prompt: "Search")
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            SortSelector(sortOrder: $sortOrder)
        }
        .task(loadAlbums)
        .onChange(of: sortOrder) {
            Task {
                await loadAlbums()
            }
        }
    }
}

// MARK: Helper

extension AlbumsView {
    @Sendable
    func loadAlbums() async {
        do {
            albums = try await dataProvider.getAlbums(limit: -1, sortOrder: sortOrder, ascending: true)
        } catch {
            errored = true
        }
    }
    
    private func filter() -> [Album] {
        if let albums = albums {
            if search == "" {
                return albums
            } else {
                return albums.filter { $0.name.lowercased().contains(search.lowercased()) }
            }
        } else {
            return []
        }
    }
}

#Preview {
    NavigationStack {
        AlbumsView()
    }
}
