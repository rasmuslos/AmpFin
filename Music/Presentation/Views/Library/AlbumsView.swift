//
//  AlbumsView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct AlbumsView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var albums: [AlbumItem]?
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
        .toolbar {
            SortSelector(sortOrder: $sortOrder)
        }
        .task(loadItems)
        .onChange(of: sortOrder) {
            Task {
                await loadItems()
            }
        }
    }
}

// MARK: Loading view

extension AlbumsView {
    struct LoadingView: View {
        var body: some View {
            ProgressView()
            Text("Loading")
                .padding()
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: Error view

extension AlbumsView {
    struct ErrorView: View {
        var body: some View {
            Text("Unable to load")
                .foregroundStyle(.red)
        }
    }
}

// MARK: Helper

extension AlbumsView {
    @Sendable
    func loadItems() async {
        do {
            albums = try await JellyfinClient.shared.getAlbums(limit: -1, sortOrder: sortOrder, ascending: true)
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
