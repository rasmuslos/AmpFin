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
    
    @State var success = false
    @State var failure = false
    
    @State private var count = 0
    @State private var albums = [Album]()
    
    @State private var search: String = ""
    @State private var searchTask: Task<Void, Error>?

    
    var sortState: [String] {[
        search,
        sortOrder.rawValue,
        sortAscending.description,
    ]}
    
    var body: some View {
        VStack {
            if failure {
                ErrorView()
            } else if success {
                ScrollView {
                    AlbumGrid(albums: albums, count: count, loadMore: { () async -> Void in await fetchAlbums(shouldReset: false) })
                        .padding(.horizontal, .outerSpacing)
                }
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "search.albums")
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.albums")
        .modifier(NowPlaying.SafeAreaModifier())
        .toolbar {
            SortSelector(ascending: $sortAscending, sortOrder: $sortOrder)
        }
        .task {
            if albums.isEmpty {
                await fetchAlbums(shouldReset: false)
            }
        }
        .onChange(of: sortState) {
            searchTask?.cancel()
            searchTask = Task {
                try await Task.sleep(nanoseconds: UInt64(0.5 * TimeInterval(NSEC_PER_SEC)))
                await fetchAlbums(shouldReset: true)
                searchTask = nil
            }
        }
    }
}

// MARK: Helper

private extension AlbumsView {
    func fetchAlbums(shouldReset: Bool) async {
        failure = false
        
        var search: String? = search
        
        if self.search.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            search = nil
        }
        
        if shouldReset {
            count = 0
            albums = []
        }
        
        do {
            let result = try await dataProvider.getAlbums(limit: 100, startIndex: albums.count, sortOrder: sortOrder, ascending: sortAscending, search: search)
            
            count = result.1
            albums += result.0
            
            success = true
        } catch {
            failure = true
        }
    }
}

#Preview {
    NavigationStack {
        AlbumsView()
    }
}
