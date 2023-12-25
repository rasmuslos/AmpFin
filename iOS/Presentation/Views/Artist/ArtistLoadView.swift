//
//  ArtistLoadView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AFBaseKit

struct ArtistLoadView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let artistId: String
    
    @State var artist: Artist?
    @State var failed = false
    
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
