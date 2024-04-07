//
//  tracks.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase

struct TracksView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var tracks: [Track]?
    @State var errored = false
    
    @State var ascending = SortSelector.getAscending()
    @State var sortOrder = SortSelector.getSortOrder()
#if targetEnvironment(macCatalyst)
    @Environment(NowPlayingViewState.self) private var viewState
#endif
    
    var sortState: [String] {[
        ascending.description,
        sortOrder.rawValue,
    ]}
    
    var body: some View {
        VStack {
            if let tracks = tracks {
                List {
                    TrackList(tracks: tracks, loadMore: loadTracks)
                }
                .listStyle(.plain)
            } else if errored {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.tracks")
#if targetEnvironment(macCatalyst)
        .toolbar(viewState.presented ? .hidden : .automatic,
                for: .navigationBar)
#endif
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            SortSelector(ascending: $ascending, sortOrder: $sortOrder)
        }
        .task {
            loadTracks()
        }
        .onChange(of: sortState) {
            tracks = nil
            loadTracks()
        }
    }
}

// MARK: Helper

extension TracksView {
    func loadTracks() {
        errored = false
        Task {
            do {
                if tracks != nil {
                    let newTracks = try await dataProvider.getPagedTracks(limit: 100, startIndex: tracks!.count, sortOrder: sortOrder, ascending: ascending)
                    tracks!.append(contentsOf: newTracks)
                } else {
                    tracks = try await dataProvider.getPagedTracks(limit: 100, startIndex: 0, sortOrder: sortOrder, ascending: ascending)}
            } catch {
                errored = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        TracksView()
    }
}
