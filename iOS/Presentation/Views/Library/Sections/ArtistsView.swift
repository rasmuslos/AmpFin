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
    
    @State private var failed = false
    @State private var artists = [Artist]()
    
    var body: some View {
        VStack {
            if failed {
                ErrorView()
            } else if !artists.isEmpty {
                ArtistList(artists: artists)
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
    func fetchArtists() async {
        failed = false
        
        do {
            artists = try await dataProvider.getArtists(albumOnly: albumOnly)
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
