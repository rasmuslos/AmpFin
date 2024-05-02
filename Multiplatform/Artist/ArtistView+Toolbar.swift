//
//  ArtistView+Toolbar.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 08.04.24.
//

import SwiftUI
import Defaults
import AFBase
import AFPlayback

extension ArtistView {
    struct Toolbar: ViewModifier {
        @Default(.sortOrder) private var sortOrder
        @Default(.sortAscending) private var sortAscending
        
        let artist: Artist
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(artist.name)
                .modifier(AdditionalToolbarModifier(artist: artist))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                await artist.setFavorite(favorite: !artist.favorite)
                            }
                        } label: {
                            Label("favorite", systemImage: artist.favorite ? "heart.fill" : "heart")
                                .labelStyle(.iconOnly)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        SortSelector(ascending: $sortAscending, sortOrder: $sortOrder)
                    }
                }
        }
    }
}

extension ArtistView.Toolbar {
    struct AdditionalToolbarModifier: ViewModifier {
        @Default(.artistInstantMix) private var artistInstantMix
        @Environment(\.libraryDataProvider) private var dataProvider
        
        let artist: Artist
        
        func body(content: Content) -> some View {
            if artist.cover == nil {
                content
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                if artistInstantMix {
                                    Task {
                                        try? await artist.startInstantMix()
                                    }
                                } else {
                                    Task {
                                        let tracks = try await dataProvider.getTracks(artistId: artist.id, sortOrder: .random, ascending: true)
                                        AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: .init(container: artist))
                                    }
                                }
                            } label: {
                                Label("queue.mix", systemImage: "play.circle.fill")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
            } else {
                content
                    .ignoresSafeArea(edges: .top)
            }
        }
    }
}
