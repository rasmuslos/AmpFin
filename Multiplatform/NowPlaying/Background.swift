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
        
        private let speed = CGFloat.random(in: 0.1...0.4)
        
        @State private var offset = CGFloat.random(in: 0...1)
        
        var body: some View {
            ZStack {
                Color.black
                Color.gray.opacity(0.8)
                
                ZStack {
                    if let cover = viewModel.nowPlaying?.cover {
                        GeometryReader { proxy in
                            let width = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
                            let height = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                            
                            ItemImage(cover: cover)
                                .id(cover.url)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: width, height: height)
                                .blur(radius: 100)
                        }
                        
                        FluidGradient(blobs: viewModel.colors, highlights: viewModel.highlights, speed: viewModel.playing && !haltNowPlayingBackground ? speed : 0, blur: 0.7)
                    }
                }
                .overlay {
                    Color.black.opacity(0.2)
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .all)
        }
    }
}
