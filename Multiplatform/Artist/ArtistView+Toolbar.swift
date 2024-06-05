//
//  ArtistView+Toolbar.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 08.04.24.
//

import SwiftUI
import Defaults
import AmpFinKit
import AFPlayback

internal extension ArtistView {
    struct Toolbar: ViewModifier {
        let artist: Artist
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(artist.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        SortSelector()
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            artist.favorite.toggle()
                        } label: {
                            Label("favorite", systemImage: artist.favorite ? "star.fill" : "star")
                                .labelStyle(.iconOnly)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                }
                .modifier(AdditionalToolbarModifier(artist: artist))
        }
    }
}


private struct AdditionalToolbarModifier: ViewModifier {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    @Default(.artistInstantMix) private var artistInstantMix
    
    let artist: Artist
    
    func body(content: Content) -> some View {
        if artist.cover == nil {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                if artistInstantMix {
                                    try? await artist.startInstantMix()
                                } else {
                                    let tracks = try await dataProvider.tracks(artistId: artist.id, sortOrder: .random, ascending: true)
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

