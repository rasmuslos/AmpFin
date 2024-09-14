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
        
        @State private var offset = CGFloat.random(in: 0...1)
        @State private var baseSpeed = CGFloat.random(in: 0.2...0.3)
        
        private var speed: CGFloat {
            guard viewModel.finished && viewModel.playing && !haltNowPlayingBackground else {
                return 0
            }
            
            if viewModel.highlights.count < 3 {
                return 0.1
            } else if viewModel.highlights.count < 5 {
                return baseSpeed
            }
            
            return baseSpeed * 2
        }
        private var blurRadius: CGFloat {
            guard viewModel.finished else {
                return 0
            }
            
            if viewModel.currentTab == .lyrics {
                return 0.7
            }
            
            if viewModel.highlights.count < 3 {
                return 0.9
            } else if viewModel.highlights.count < 5 {
                return 0.8
            }
            
            return 0.7
        }
        private var highlights: [Color] {
            if viewModel.highlights.isEmpty {
                return []
            } else if viewModel.highlights.count < 3, let first = viewModel.highlights.first {
                return [first, first, first] + viewModel.highlights
            }
            
            return viewModel.highlights
        }
        
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
                        
                        FluidGradient(blobs: viewModel.colors, highlights: highlights, speed: speed, blur: blurRadius)
                            .opacity(viewModel.finished ? 1 : 0)
                            .animation(.smooth, value: viewModel.colors)
                            .animation(.smooth, value: viewModel.highlights)
                            .animation(.smooth, value: viewModel.finished)
                    }
                }
                .overlay(viewModel.highlights.count < 5 ? .black.opacity(0.2) : .clear)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .all)
        }
    }
}
