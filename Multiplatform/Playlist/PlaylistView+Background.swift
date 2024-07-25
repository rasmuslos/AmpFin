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
        
        @State private var colors = [Color]()
        @State private var highlighted: Color?
        
        private var highlights: [Color] {
            guard let highlighted else {
                return [.accentColor]
            }
            
            return [highlighted]
        }
        
        var body: some View {
            FluidGradient(blobs: colors, highlights: highlights, speed: 0.1, blur: 0.7)
                .background(.tertiary)
                .task {
                    await update(cover: playlist.cover)
                }
        }
        
        private nonisolated func update(cover: Cover?) async {
            if let cover {
                guard let dominantColors = try? await AFVisuals.extractDominantColors(10, cover: cover) else {
                    await MainActor.run {
                        withAnimation {
                            self.colors = []
                            self.highlighted = nil
                        }
                    }
                    
                    return
                }
                
                let colors = dominantColors.map { $0.color }
                let mostSaturated = AFVisuals.determineSaturated(colors)
                
                await MainActor.run { [colors, mostSaturated] in
                    withAnimation {
                        self.colors = colors.filter { $0 != highlighted }
                        self.highlighted = mostSaturated
                    }
                }
            }
        }
    }
}

#Preview {
    PlaylistView.Background.init(playlist: Playlist.fixture)
}
