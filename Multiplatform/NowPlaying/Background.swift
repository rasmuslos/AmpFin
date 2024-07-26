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
        @Environment(ViewModel.self) private var viewModel
        
        private let speed = CGFloat.random(in: 0.2...0.5)
        private var highlights: [Color] {
            guard let highlighted = viewModel.highlighted else {
                return []
            }
            
            return [highlighted]
        }
        
        var body: some View {
            ZStack {
                if let cover = viewModel.track?.cover {
                    Color.black
                    
                    ItemImage(cover: cover)
                        .id(cover.url)
                        .blur(radius: 100)
                        .frame(maxWidth: .infinity)
                    
                    FluidGradient(blobs: viewModel.colors, highlights: highlights, speed: AudioPlayer.current.playing ? speed : 0, blur: 0.9)
                        .ignoresSafeArea(edges: .all)
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
                    UnevenRoundedRectangle(topLeadingRadius: viewModel.showRoundedCorners ? UIScreen.main.displayCornerRadius : 0,
                                           bottomLeadingRadius: 0,
                                           bottomTrailingRadius: 0,
                                           topTrailingRadius: viewModel.showRoundedCorners ? UIScreen.main.displayCornerRadius : 0,
                                           style: .continuous)
                    .frame(height: 50)
                    
                    Rectangle()
                }
            }
            #endif
        }
    }
}
