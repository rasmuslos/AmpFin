//
//  ArtistLoadView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

struct ArtistLoadView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let artistId: String
    
    @State var artist: Artist?
    @State var failed = false
    
    init(artistId: String, artist: Artist? = nil, failed: Bool = false) {
        self.artistId = artistId
    }
    
    // TODO: LOAD
    
    var body: some View {
        if failed {
            ErrorView()
        } else if let artist = artist {
            ArtistView(artist: artist)
        } else {
            LoadingView()
                .task {
                    if let artist = try? await dataProvider.getArtistById(artistId) {
                        self.artist = artist
                    } else {
                        self.failed = true
                    }
                }
        }
    }
}
