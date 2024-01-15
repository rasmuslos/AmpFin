//
//  tracks.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBaseKit

struct TracksView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var tracks: [Track]?
    @State var errored = false
    
    @State var ascending = SortSelector.getAscending()
    @State var sortOrder = SortSelector.getSortOrder()
    
    var sortState: [String] {[
        ascending.description,
        sortOrder.rawValue,
    ]}
    
    var body: some View {
        VStack {
            if let tracks = tracks {
                List {
                    TrackList(tracks: tracks)
                }
                .listStyle(.plain)
            } else if errored {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.tracks")
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            SortSelector(ascending: $ascending, sortOrder: $sortOrder)
        }
        .task(loadTracks)
        .onChange(of: sortState) {
            Task {
                await loadTracks()
            }
        }
    }
}

// MARK: Helper

extension TracksView {
    @Sendable
    func loadTracks() async {
        errored = false
        
        do {
            tracks = try await dataProvider.getAllTracks(sortOrder: sortOrder, ascending: ascending)
        } catch {
            errored = true
        }
    }
}

#Preview {
    NavigationStack {
        TracksView()
    }
}
