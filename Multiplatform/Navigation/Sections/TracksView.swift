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
    @Environment(\.libraryDataProvider) private var dataProvider
    
    @State private var count = 0
    @State private var success = false
    @State private var failure = false
    @State private var tracks = [Track]()
    
    @State private var search: String = ""
    
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
                List {
                    TrackList(tracks: tracks, count: count, loadMore: loadTracks)
                }
                .listStyle(.plain)
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.tracks")
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "search.tracks")
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            SortSelector(ascending: $sortAscending, sortOrder: $sortOrder)
        }
        .task {
            reset()
            await loadTracks()
        }
        .refreshable {
            reset()
            await loadTracks()
        }
        .onChange(of: sortState) {
            Task {
                reset()
                await loadTracks()
            }
        }
    }
}

// MARK: Helper

extension TracksView {
    func reset() {
        count = 0
        tracks = []
    }
    
    func loadTracks() async {
        failure = false
        
        let search: String?
        
        if self.search.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            search = nil
        } else {
            search = self.search
        }
        
        do {
            let result = try await dataProvider.getTracks(limit: 100, startIndex: tracks.count, sortOrder: sortOrder, ascending: sortAscending, search: search)
            
            count = result.1
            tracks += result.0
            
            success = true
        } catch {
            failure = true
        }
    }
}

#Preview {
    NavigationStack {
        TracksView()
    }
}
