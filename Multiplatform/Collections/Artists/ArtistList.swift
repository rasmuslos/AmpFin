//
//  ArtistList.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AmpFinKit

struct ArtistList: View {
    let artists: [Artist]
    
    var count = 0
    var loadMore: LoadCallback? = nil
    
    var body: some View {
        ForEach(artists) { artist in
            ArtistListRow(artist: artist)
                .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                .onAppear {
                    if artist == artists.last {
                        loadMore?()
                    }
                }
        }
        
        ForEach(0..<(max(0, count - artists.count)), id: \.hashValue) { _ in
            ArtistListRow.placeholder
                .onAppear { loadMore?() }
        }
    }
}

internal extension ArtistList {
    typealias LoadCallback = (() -> Void)
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
            .padding(.horizontal, 20)
        }
        .listStyle(.plain)
    }
}
