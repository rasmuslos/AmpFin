//
//  tracks.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import Defaults
import AFBase

struct TracksView: View {
    @Default(.sortOrder) private var sortOrder
    @Default(.sortAscending) private var sortAscending
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var count = 0
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
                    TrackList(tracks: tracks, count: count, loadMore: loadTracks)
                }
                .listStyle(.plain)
            } else if failed {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.tracks")
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            SortSelector(ascending: $sortAscending, sortOrder: $sortOrder)
        }
        .task { await loadTracks() }
        .refreshable { await loadTracks() }
        .onChange(of: sortState) {
            Task {
                tracks = []
                await loadTracks()
            }
        }
    }
}

// MARK: Helper

extension TracksView {
    func loadTracks() async {
        failed = false
        
        do {
            let result = try await dataProvider.getTracks(limit: 100, startIndex: tracks.count, sortOrder: sortOrder, ascending: sortAscending)
            
            count = result.1
            tracks += result.0
        } catch {
            failed = true
        }
    }
}

#Preview {
    NavigationStack {
        TracksView()
    }
}
