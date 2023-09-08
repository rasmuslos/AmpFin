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
    
    var body: some View {
        VStack {
            if let albums = albums {
                ScrollView {
                    AlbumGrid(albums: albums)
                        .padding()
                }
            } else if errored {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Albums")
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
}

#Preview {
    NavigationStack {
        AlbumsView()
    }
}
