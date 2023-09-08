//
//  ArtistLoadView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

struct ArtistLoadView: View {
    let artistId: String
    
    @State var artist: Artist?
    
    // TODO: LOAD
    
    var body: some View {
        if let artist = artist {
            ArtistView(artist: artist)
        } else {
            LoadingView()
        }
    }
}
