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
    @State private var success = false
    @State private var failed = false
    @State private var artists = [Artist]()

    
    var body: some View {
        VStack {
            if success {
                ArtistList(artists: artists, count: count, loadMore: fetchArtists)
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
