//
//  FavoritesView.swift
//  Music
//
//  Created by Rasmus Krämer on 24.09.23.
//

import SwiftUI
import Defaults
import AFBase

struct FavoritesView: View {
    @Default(.sortOrder) private var sortOrder
    @Default(.sortAscending) private var sortAscending
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var failed = false
    @State var tracks = [Track]()
    
    var sortState: [String] {[
        sortOrder.rawValue,
        sortAscending.description,
    ]}
    
    var body: some View {
        VStack {
            if !tracks.isEmpty {
                List {
                    TrackList(tracks: tracks)
                }
                .listStyle(.plain)
            } else if failed {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.favorites")
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            SortSelector(ascending: $sortAscending, sortOrder: $sortOrder)
        }
        .task { await fetchTracks() }
        .refreshable { await fetchTracks() }
        .onChange(of: sortState) {
            Task {
                await fetchTracks()
            }
        }
    }
}

extension FavoritesView {
    func fetchTracks() async {
        failed = false
        
        do {
            tracks = try await dataProvider.getFavoriteTracks(sortOrder: sortOrder, ascending: sortAscending)
        } catch {
            failed = true
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
}
