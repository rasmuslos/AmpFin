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
        Group {
            if success {
                List {
                    ArtistList(artists: artists, count: count, expand: expand)
                        .padding(.horizontal, 20)
                }
                .listStyle(.plain)
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "search.artists")
                .onChange(of: search) {
                    searchTask?.cancel()
                    searchTask = Task {
                        try await Task.sleep(nanoseconds: UInt64(0.5 * TimeInterval(NSEC_PER_SEC)))
                        await fetchArtists(search: self.search)
                        searchTask = nil
                    }
                }
            } else if failed {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle(albumOnly ? "title.albumArtists" : "title.artists")
        .modifier(NowPlaying.SafeAreaModifier())
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
