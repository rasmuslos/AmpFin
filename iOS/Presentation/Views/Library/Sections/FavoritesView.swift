//
//  FavoritesView.swift
//  Music
//
//  Created by Rasmus Krämer on 24.09.23.
//

import SwiftUI
import AFBase

struct FavoritesView: View {
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
                    TrackList(tracks: tracks)
                }
                .listStyle(.plain)
            } else if errored {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle("title.favorites")
#if targetEnvironment(macCatalyst)
        .toolbar(viewState.presented ? .hidden : .automatic,
                for: .navigationBar)
#endif
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

extension FavoritesView {
    @Sendable
    func loadTracks() async {
        errored = false
        
        do {
            tracks = try await dataProvider.getFavoriteTracks(sortOrder: sortOrder, ascending: ascending)
        } catch {
            errored = true
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
}
