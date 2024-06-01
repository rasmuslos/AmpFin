//
//  ArtistLoadView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AmpFinKit

struct ArtistLoadView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let artistId: String
    
    @State private var failed = false
    @State private var artist: Artist?
    
    var body: some View {
        if failed {
            ErrorView()
                .refreshable { await loadArtist() }
        } else if let artist {
            ArtistView(artist: artist)
        } else {
            LoadingView()
                .task { await loadArtist() }
                .refreshable { await loadArtist() }
        }
    }
    
    private func loadArtist() async {
        guard let artist = try? await dataProvider.artist(identifier: artistId) else {
            failed = true
            return
        }
        
        self.artist = artist
    }
}
