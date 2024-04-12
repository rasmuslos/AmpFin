//
//  ArtistsView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AFBase

struct ArtistsView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let albumOnly: Bool
    
    @State var count = 0
    @State private var working = false
    @State private var search: String = ""
    @State private var success = false
    @State private var failed = false
    @State private var artists = [Artist]()
    @State private var searchTask: Task<Void, Error>?
    
    var body: some View {
        VStack {
            if success {
                ArtistList(artists: artists, count: count, expand: expand)
                    .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "search.artists")
                    .onChange(of: search) {
                        searchTask?.cancel()
                        searchTask = Task {
                            if !working {
                                try await Task.sleep(nanoseconds: UInt64(0.5 * TimeInterval(NSEC_PER_SEC)))
                                working = true
                                await fetchArtists(search: self.search)
                                working = false
                                searchTask = nil
                            }
                        }
                    }
            } else if failed {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle(albumOnly ? "title.albumArtists" : "title.artists")
        .modifier(NowPlayingBarSafeAreaModifier())
        .task { await fetchArtists() }
        .refreshable { await fetchArtists() }
    }
}

// MARK: Helper

extension ArtistsView {
    func expand() {
        if !working && count > artists.count {
            working = true
            
            let search: String?
            
            if self.search.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                search = nil
            } else {
                search = self.search
            }
            Task.detached {
                await fetchArtists(search: search)
                working = false
            }
        }
    }
    
    func fetchArtists(search: String? = nil) async {
        failed = false
        
        if search != nil {
            count = 0
            artists = []
        }
        
        do {
            let result = try await dataProvider.getArtists(limit: 100, startIndex: artists.count, albumOnly: albumOnly, search: search)
            
            count = result.1
            artists += result.0
            
            success = true
        } catch {
            failed = true
        }
    }
}

#Preview {
    NavigationStack {
        ArtistsView(albumOnly: false)
    }
}

#Preview {
    NavigationStack {
        ArtistsView(albumOnly: true)
    }
}
