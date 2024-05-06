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
        ForEach(artists) { artist in
            ArtistListRow(artist: artist)
                .listRowInsets(.init(top: .connectedSpacing, leading: 0, bottom: .connectedSpacing, trailing: 0))
                .onAppear {
                    if artist == artists.last {
                        expand?()
                    }
                }
        }
        
        ForEach(0..<(max(0, count - artists.count)), id: \.hashValue) { _ in
            ArtistListRow.placeholder
                .onAppear { expand?() }
        }
    }
}

extension ArtistList {
    typealias Expand = (() -> Void)
}

#Preview {
    NavigationStack {
        List {
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
        .listStyle(.plain)
    }
}
