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
    
    @State var artists: [Artist]?
    @State var errored = false
    
    var body: some View {
        VStack {
            if let artists = artists {
                ArtistList(artists: artists)
            } else if errored {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle(albumOnly ? "title.albumArtists" : "title.artists")
        .modifier(NowPlayingBarSafeAreaModifier())
        .task(loadArtists)
    }
}

// MARK: Helper

extension ArtistsView {
    @Sendable
    func loadArtists() async {
        errored = false
        
        do {
            artists = try await dataProvider.getArtists(albumOnly: albumOnly)
        } catch {
            errored = true
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
