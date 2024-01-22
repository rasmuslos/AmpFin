//
//  PlaylistView+Background.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AFBaseKit
import FluidGradient

extension PlaylistView {
    struct Background: View {
        let playlist: Playlist
        @State var colors: ImageColors?
        
        var body: some View {
            if let colors = colors {
                FluidGradient(blobs: [colors.background, colors.detail, colors.secondary, colors.primary], highlights: [], speed: 0.1, blur: 0.7)
                    .background(.tertiary)
            } else {
                Rectangle()
                    .foregroundStyle(.tertiary)
                    .onAppear {
                        Task.detached {
                            if let colors = await ImageColors.getImageColors(cover: playlist.cover) {
                                withAnimation {
                                    self.colors = colors
                                }
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    PlaylistView.Background.init(playlist: Playlist.fixture)
}
