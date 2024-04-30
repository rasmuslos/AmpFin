//
//  NowPlayingBackground.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import Foundation
import SwiftUI
import FluidGradient
import AFBase

struct NowPlayingBackground: View {
    let cover: Item.Cover?
    
    @State private var imageColors: ImageColors?
    
    var body: some View {
        ZStack {
            if let cover = cover {
                Color.black
                
                ItemImage(cover: cover)
                    .id(cover.url)
                    .blur(radius: 100)
                    .frame(maxWidth: .infinity)
                
                if let imageColors = imageColors {
                    FluidGradient(blobs: [imageColors.background, imageColors.detail, imageColors.primary, imageColors.secondary], speed: CGFloat.random(in: 0.2...0.4), blur: 0.8)
                        .ignoresSafeArea(edges: .all)
                        .onChange(of: cover.url) { determineImageColors() }
                } else {
                    Color.clear
                        .onAppear { determineImageColors() }
                }
            } else {
                Color.black
                Color.gray.opacity(0.8)
            }
        }
        .ignoresSafeArea(edges: .all)
        .overlay(.black.opacity(0.25))
        .allowsHitTesting(false)
    }
    
    private func determineImageColors() {
        Task.detached {
            let imageColors = await ImageColors.getImageColors(cover: cover)
            imageColors?.updateHue(saturation: 0.6, luminance: 0.6)
            
            withAnimation(.easeInOut(duration: 1)) {
                self.imageColors = imageColors
            }
        }
    }
}


enum NowPlayingTab {
    case cover
    case lyrics
    case queue
}
