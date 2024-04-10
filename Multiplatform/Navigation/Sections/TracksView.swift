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
    @State var success = false
    @State var failure = false
    @State var tracks = [Track]()
    
    var sortState: [String] {[
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
    func loadTracks(search: String? = nil) async {
        failure = false
        
        if search != nil {
            tracks = []
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
