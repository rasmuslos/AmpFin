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
    var expand: Expand? = nil
    
    var body: some View {
        List {
            ForEach(artists) { artist in
                ArtistListRow(artist: artist, expand: artist == artists.last ? expand : nil)
            }
            ForEach(0..<(max(0, count - artists.count)), id: \.hashValue) { _ in
                ArtistListRow.placeholder
                    .onAppear { expand?() }
            }
        }
        .listStyle(.plain)
    }
}

extension ArtistList {
    typealias Expand = (() -> Void)
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
