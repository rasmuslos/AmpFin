//
//  NowPlayingBackground.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import Foundation
import SwiftUI
import Defaults
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    struct Background: View {
        @Default(.haltNowPlayingBackground) private var haltNowPlayingBackground
        @Environment(ViewModel.self) private var viewModel
        
        var body: some View {
            ZStack {
                Color.black
                Color.gray.opacity(0.8)
                
                ZStack {
                    if let cover = viewModel.nowPlaying?.cover {
                        GeometryReader { proxy in
                            ItemImage(cover: cover)
                                .id(cover.url)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                                       height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom)
                                .blur(radius: 150)
                        
                            if #available(iOS 18, *), false {
                                MeshGradient(width: 4, height: 4, points: viewModel.colors.map { _ in .init(.random(in: 0...4), .random(in: 0...4)) }, colors: viewModel.colors, smoothsColors: true)
                            }
                        }
                    }
                }
                .overlay(.black.opacity(0.2))
            }
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .all)
        }
    }
}
