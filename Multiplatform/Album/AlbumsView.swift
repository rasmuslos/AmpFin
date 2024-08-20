//
//  AlbumsView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import Defaults
import AmpFinKit

internal struct AlbumsView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    @Default(.sortOrder) private var sortOrder
    @Default(.sortAscending) private var sortAscending
    
    @State private var success = false
    @State private var failure = false
    @State private var working = false
    
    @State private var count = 0
    @State private var albums = [Album]()
    
    @State private var search: String = ""
    @State private var task: Task<Void, Error>?
    
    
    var sortState: [String] {[
        search,
        sortAscending.description,
        sortOrder.hashValue.description,
    ]}
    
    var body: some View {
        VStack {
            if success {
                ScrollView {
                    AlbumGrid(albums: albums, count: count) {
                        loadAlbums(reset: false)
                    }
                    .padding(.horizontal, 20)
                }
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "search.albums")
            } else if failure {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.albums")
        .modifier(NowPlaying.SafeAreaModifier())
        .toolbar {
            SortSelector()
        }
        .onAppear {
            if albums.isEmpty {
                loadAlbums(reset: true)
            }
        }
        .onDisappear {
            task?.cancel()
        }
        .onChange(of: sortState) {
            loadAlbums(reset: true)
        }
        .refreshable {
            await withTaskCancellationHandler {
                loadAlbums(reset: true)
            } onCancel: {
                Task {
                    await task?.cancel()
                }
            }
        }
    }
    
    private func loadAlbums(reset: Bool) {
        failure = false
        
        if reset {
            count = 0
            albums = []
            
            working = false
        }
        
        guard !working, count == 0 || count > albums.count else {
            return
        }
        
        working = true
        
        task?.cancel()
        task = Task.detached(priority: .userInitiated) {
            guard let result = try? await dataProvider.albums(limit: 100, startIndex: albums.count, sortOrder: sortOrder, ascending: sortAscending, search: search) else {
                await MainActor.withAnimation {
                    failure = true
                }
                return
            }
            
            try Task.checkCancellation()
            
            await MainActor.withAnimation {
                count = result.1
                albums += result.0
                
                success = true
                working = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        AlbumsView()
    }
}
