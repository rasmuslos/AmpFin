//
//  NowPlayingBackground.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import Foundation
import SwiftUI
import FluidGradient
import Defaults
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    struct Background: View {
        @Default(.haltNowPlayingBackground) private var haltNowPlayingBackground
        @Environment(ViewModel.self) private var viewModel
        
        private let speed = CGFloat.random(in: 0.2...0.5)
        
        @State private var size: CGFloat = .zero
        @State private var offset = CGFloat.random(in: 0...1)
        
        var body: some View {
            ZStack {
                if let cover = viewModel.nowPlaying?.cover {
                    Color.black
                    
                    GeometryReader { proxy in
                        let width = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
                        let height = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                        
                        Color.clear
                            .fixedSize()
                            .overlay {
                                let offsetX = max(0, size - width) * offset
                                let offsetY = max(0, size - height) * offset
                                
                                ItemImage(cover: cover)
                                    .id(cover.url)
                                    .frame(width: size, height: size)
                                    .offset(x: -offsetX, y: offsetY)
                                    .blur(radius: 100)
                            }
                            .onChange(of: proxy.size, initial: true) {
                                size = max(size, max(width, height) + 400)
                            }
                    }
                    
                    FluidGradient(blobs: viewModel.colors, highlights: viewModel.highlights, speed: viewModel.playing && !haltNowPlayingBackground ? speed : 0, blur: 0.9)
                        .ignoresSafeArea(edges: .all)
                } else {
                    Color.black
                    Color.gray.opacity(0.8)
                }
            }
            .allowsHitTesting(false)
            .overlay(.black.opacity(0.25))
        }
    }
}
