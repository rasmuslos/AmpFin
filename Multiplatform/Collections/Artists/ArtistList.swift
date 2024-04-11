//
//  ArtistList.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AFBase

struct ArtistList: View {
    let artists: [Artist]
    
    var count = 0
    var loadMore: LoadCallback = nil
    
    @State private var working = false
    @State private var search: String = ""
    
    var body: some View {
        let filtered = filter(artists: artists)
        List {
            ForEach(filtered) { artist in
                ModifiedArtistListRow(artist: artist, expand: artist == filtered.last ? expand : nil)
            }
            ForEach(0..<(max(0, count - artists.count)), id: \.hashValue) { _ in
                ArtistListRow.placeholder
                    .onAppear { expand() }
            }
        }
        .listStyle(.plain)
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "search.artists")
        .onChange(of: search) {
            Task {
                if !working {
                    working = true
                    await loadMore?(self.search)
                    working = false
                }
            }
        }
    }
}

extension ArtistList {
    typealias Expand = (() -> Void)
    typealias LoadCallback = ((_ search: String?) async -> Void)?
    
    func expand() {
        if !working && count > artists.count, let loadMore = loadMore {
            working = true
            
            let search: String?
            
            if self.search.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                search = nil
            } else {
                search = self.search
            }
            
                Task.detached {
                    await loadMore(search)
                    working = false
            }
        }
    }
    
    private func filter(artists: [Artist]) -> [Artist] {
        var artists = artists
        
        if search != "" {
            artists = artists.filter { $0.name.lowercased().contains(search.lowercased())}
        }
        
        return artists
    }
    
    struct ModifiedArtistListRow: View {
        let artist: Artist
        let expand: Expand?
        
        var body: some View {
            ArtistListRow(artist: artist)
                .onAppear { expand?() }
        }
    }
}

#Preview {
    NavigationStack {
        ArtistList(artists: [
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
            Artist.fixture,
        ])
    }
}
