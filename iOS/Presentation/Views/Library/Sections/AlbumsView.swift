//
//  AlbumsView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase

struct AlbumsView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var albums: [Album]?
    @State var errored = false
    
    @State var ascending = SortSelector.getAscending()
    @State var sortOrder = SortSelector.getSortOrder()
    @State var search: String = ""
    
    var sortState: [String] {[
        ascending.description,
        sortOrder.rawValue,
    ]}
    
    var body: some View {
        VStack {
            if albums != nil {
                ScrollView {
                    AlbumsGrid(albums: filter())
                        .padding()
                }
            } else if errored {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.albums")
        .searchable(text: $search, prompt: "search.albums")
        .modifier(NowPlayingBarModifier())
        .toolbar {
            SortSelector(ascending: $ascending, sortOrder: $sortOrder)
        }
        .refreshable(action: loadAlbums)
        .task(loadAlbums)
        .onChange(of: sortState) {
            loadAlbums()
        }
    }
}

// MARK: Helper

extension AlbumsView {
    @Sendable
    func loadAlbums() {
        errored = false
        
        Task.detached {
            do {
                albums = try await dataProvider.getAlbums(limit: -1, sortOrder: sortOrder, ascending: ascending)
            } catch {
                errored = true
            }
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
