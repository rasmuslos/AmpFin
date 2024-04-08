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
    
    var body: some View {
        List {
            ForEach(artists) {
                ArtistListRow(artist: $0)
            }
        }
        .listStyle(.plain)
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
