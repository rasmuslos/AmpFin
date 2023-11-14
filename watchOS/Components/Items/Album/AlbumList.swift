//
//  AlbumList.swift
//  watchOS
//
//  Created by Rasmus Krämer on 14.11.23.
//

import SwiftUI
import MusicKit

struct AlbumList: View {
    var albums: [Album]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(albums) {
                        AlbumTab(album: $0)
                            .tag($0.id)
                            .padding(.vertical, -3)
                            .scrollTransition { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.8)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

#Preview {
    AlbumList(albums: [
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
    ])
}
