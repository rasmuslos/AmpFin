//
//  PlaylistView+Background.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import FluidGradient
import AmpFinKit

internal extension PlaylistView {
    struct Background: View {
        let playlist: Playlist
        
        @State private var imageColors = ImageColors()
        
        var body: some View {
            FluidGradient(blobs: [imageColors.background, imageColors.detail, imageColors.secondary, imageColors.primary], highlights: [], speed: 0.1, blur: 0.7)
                .background(.tertiary)
                .task {
                    await imageColors.update(cover: playlist.cover)
                }
        }
    }
}

#Preview {
    PlaylistView.Background.init(playlist: Playlist.fixture)
}
