//
//  tracks.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import Defaults
import AmpFinKit
import AFPlayback

internal struct TracksView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.sortOrder) private var sortOrder
    @Default(.sortAscending) private var sortAscending
    
    let favoritesOnly: Bool
    
    @State private var success = false
    @State private var failure = false
    @State private var working = false
    
    @State private var count = 0
    @State private var tracks = [Track]()
    
    @State private var search: String = ""
    @State private var task: Task<Void, Error>?
    
    var viewState: [String] {[
        search,
        sortAscending.description,
        sortOrder.hashValue.description,
    ]}
    
    private var compactLayout: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        Group {
            if success {
                Group {
                    if compactLayout {
                        List {
                            TrackListButtons(startPlayback: startPlayback)
                                .listRowSeparator(.hidden)
                                .listRowInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))
                                .padding(.horizontal, 20)
                            
                            TrackList(tracks: tracks, container: nil, count: count) {
                                loadTracks(reset: false)
                            }
                            .padding(.horizontal, 20)
                        }
                        .listStyle(.plain)
                        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "search.tracks")
                        .toolbar {
                            SortSelector()
                        }
                    } else {
                        TrackTable(tracks: tracks, container: nil, count: count) {
                            loadTracks(reset: false)
                        }
                        .searchable(text: $search, placement: .toolbar, prompt: "search.tracks")
                        .toolbar {
                            Button(action: { startPlayback(shuffled: true) }) {
                                Label("queue.play", systemImage: "play")
                                    .symbolVariant(.circle)
                            }
                            
                            Button(action: { startPlayback(shuffled: true) }) {
                                Label("queue.shuffle", systemImage: "shuffle")
                                    .symbolVariant(.circle)
                            }
                            
                            SortSelector()
                        }
                    }
                }
            } else if failure {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle(favoritesOnly ? "title.favorites" : "title.tracks")
        .modifier(NowPlaying.SafeAreaModifier())
        .onAppear {
            if tracks.isEmpty {
                loadTracks(reset: true)
            }
        }
        .onDisappear {
            task?.cancel()
        }
        .onChange(of: viewState) {
            loadTracks(reset: true)
        }
        .refreshable {
            await withTaskCancellationHandler {
                loadTracks(reset: true)
            } onCancel: {
                Task {
                    await task?.cancel()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Item.affinityChangedNotification)) {
            guard let id = $0.object as? String else {
                return
            }
            
            guard let index = tracks.firstIndex(where: { $0.id == id }) else {
                return
            }
            
            tracks.remove(at: index)
            count -= 1
        }
    }
    
    private func loadTracks(reset: Bool) {
        failure = false
        
        if reset {
            count = 0
            tracks = []
            
            working = false
        }
        
        guard !working, count == 0 || count > tracks.count else {
            return
        }
        
        working = true
        
        task?.cancel()
        task = Task.detached(priority: .userInitiated) {
            guard let result = try? await dataProvider.tracks(limit: 100, startIndex: tracks.count, sortOrder: sortOrder, ascending: sortAscending, favoriteOnly: favoritesOnly, search: search) else {
                await MainActor.run {
                    failure = true
                }
                return
            }
            
            try Task.checkCancellation()
            
            await MainActor.run {
                count = result.1
                tracks += result.0
                
                success = true
                working = false
            }
        }
    }
    private func startPlayback(shuffled: Bool) {
        if shuffled {
            Task {
                if let tracks = try? await dataProvider.tracks(limit: 200, startIndex: 0, sortOrder: .random, ascending: false, favoriteOnly: false, search: nil).0 {
                    AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: .init(container: nil))
                } else {
                    AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: true, playbackInfo: .init(container: nil))
                }
            }
        } else {
            AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: .init(container: nil))
        }
    }
}

#Preview {
    NavigationStack {
        TracksView(favoritesOnly: false)
    }
}

#Preview {
    NavigationStack {
        TracksView(favoritesOnly: true)
    }
}
