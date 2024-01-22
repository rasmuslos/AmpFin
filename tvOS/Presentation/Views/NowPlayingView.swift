//
//  NowPlayingView.swift
//  tvOS
//
//  Created by Rasmus Krämer on 22.01.24.
//

import SwiftUI
import AFBaseKit
import AFPlaybackKit
import FluidGradient

struct NowPlayingView: View {
    @State var isPlaying = AudioPlayer.current.isPlaying()
    @State var currentTrack: Track?
    
    @State var imageColors = ImageColors()
    
    var body: some View {
        Group {
            if let currentTrack = currentTrack {
                ZStack {
                    FluidGradient(blobs: [imageColors.background, imageColors.detail, imageColors.primary, imageColors.secondary], highlights: [], speed: 0.1, blur: 0.75)
                    
                    VStack {
                        ItemImage(cover: currentTrack.cover)
                            .frame(width: 500)
                        
                        Text(currentTrack.name)
                            .font(.headline)
                            .overlay(alignment: .leadingFirstTextBaseline) {
                                Image(systemName: "waveform")
                                    .foregroundColor(.secondary)
                                    .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                                    .offset(x: -50)
                            }
                        
                        if let artistName = currentTrack.artistName {
                            Text(artistName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(140)
                }
                .ignoresSafeArea(edges: .all)
                .frame(maxWidth: .infinity)
                .toolbar(.hidden, for: .tabBar)
            } else {
                Text("playback.empty")
                    .font(.title3.smallCaps())
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: currentTrack) {
            Task.detached {
                if let imageColors = await ImageColors.getImageColors(cover: currentTrack?.cover) {
                    self.imageColors = imageColors
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPause)) { _ in
            isPlaying = AudioPlayer.current.isPlaying()
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.trackChange)) { _ in
            currentTrack = AudioPlayer.current.nowPlaying
        }
    }
}

#Preview {
    NowPlayingView()
}
