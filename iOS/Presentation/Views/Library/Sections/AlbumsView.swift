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
#if targetEnvironment(macCatalyst)
    @Environment(NowPlayingViewState.self) private var viewState
#endif
    
    var sortState: [String] {[
        ascending.description,
        sortOrder.rawValue,
    ]}
    
    var body: some View {
        VStack {
            if albums != nil {
                ScrollView {
                    AlbumsGridLazyLoad(albums: filter(), loadMore: loadAlbums)
                        .padding()
                }
            } else if errored {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.albums")
#if targetEnvironment(macCatalyst)
        .toolbar(viewState.presented ? .hidden : .automatic,
                for: .navigationBar)
#endif
        .searchable(text: $search, prompt: "search.albums")
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            SortSelector(ascending: $ascending, sortOrder: $sortOrder)
        }
        .refreshable {
            albums = nil
            loadAlbums()
        }
        .task {
            loadAlbums()
        }
        .onChange(of: sortState) {
            albums = nil
            loadAlbums()
        }
    }
}

// MARK: Helper

extension AlbumsView {
    func loadAlbums() {
        errored = false
        
        Task.detached {
            do {
                if albums != nil {
                    let newAlbums = try await dataProvider.getAlbums(limit: 100, startIndex: albums!.count, sortOrder: sortOrder, ascending: ascending)
                    albums!.append(contentsOf: newAlbums)
                } else {
                    albums = try await dataProvider.getAlbums(limit: 100, sortOrder: sortOrder, ascending: ascending)
                }
                
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
