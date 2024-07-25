//
//  NowPlayingBackground.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import Foundation
import SwiftUI
import UIKit
import FluidGradient
import AmpFinKit
import AFPlayback

extension NowPlaying {
    struct Background: View {
        let cover: Cover?
        let dragging: Bool
        
        let speed = CGFloat.random(in: 0.2...0.5)
        
        @State private var colors = [Color]()
        @State private var highlighted: Color?
        
        private var highlights: [Color] {
            guard let highlighted else {
                return []
            }
            
            return [highlighted]
        }
        
        var body: some View {
            ZStack {
                if let cover {
                    Color.black
                    
                    ItemImage(cover: cover)
                        .id(cover.url)
                        .blur(radius: 100)
                        .frame(maxWidth: .infinity)

                    #if !targetEnvironment(macCatalyst)
                    FluidGradient(blobs: colors, highlights: highlights, speed: AudioPlayer.current.playing ? speed : 0, blur: 0.9)
                        .ignoresSafeArea(edges: .all)
                    #endif
                } else {
                    Color.black
                    Color.gray.opacity(0.8)
                }
            }
            .allowsHitTesting(false)
            .overlay(.black.opacity(0.25))
            #if !os(visionOS)
            .mask {
                VStack(spacing: 0) {
                    UnevenRoundedRectangle(topLeadingRadius: dragging ? UIScreen.main.displayCornerRadius : 0, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: dragging ? UIScreen.main.displayCornerRadius : 0, style: .continuous)
                        .frame(height: 50)
                    Rectangle()
                }
            }
            #endif
            #if !targetEnvironment(macCatalyst)
            .task(id: cover?.url) {
                await update(cover: cover)
            }
            #endif
        }
        
        private nonisolated func update(cover: Cover?) async {
            if let cover {
                guard let dominantColors = try? await AFVisuals.extractDominantColors(10, cover: cover) else {
                    await MainActor.run {
                        self.colors = []
                        self.highlighted = nil
                    }
                    
                    return
                }
                
                let colors = dominantColors.map { $0.color }
                let mostSaturated = AFVisuals.determineSaturated(colors)
                
                await MainActor.run { [colors, mostSaturated] in
                    self.colors = colors.filter { $0 != highlighted }
                    self.highlighted = mostSaturated
                }
            }
        }
    }
}
