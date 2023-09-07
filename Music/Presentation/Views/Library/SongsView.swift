//
//  SongsView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct SongsView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var songs: [SongItem]?
    @State var errored = false
    
    @State var sortOrder = SortSelector.getSortOrder()
    
    var body: some View {
        VStack {
            if let songs = songs {
                List {
                    SongList(songs: songs)
                }
                .listStyle(.plain)
            } else if errored {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Songs")
        .modifier(NowPlayingBarSafeAreaModifier())
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

extension SongsView {
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

extension SongsView {
    struct ErrorView: View {
        var body: some View {
            Text("Unable to load")
                .foregroundStyle(.red)
        }
    }
}

// MARK: Helper

extension SongsView {
    @Sendable
    func loadItems() async {
        do {
            songs = try await JellyfinClient.shared.getAllSongs(sortOrder: sortOrder, ascending: true)
        } catch {
            errored = true
        }
    }
}

#Preview {
    NavigationStack {
        SongsView()
    }
}
