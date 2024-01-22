//
//  NowPlayingView.swift
//  tvOS
//
//  Created by Rasmus Krämer on 22.01.24.
//

import SwiftUI
import AFBase
import AFPlayback
import FluidGradient

struct NowPlayingView: View {
    @State var isPlaying = AudioPlayer.current.isPlaying()
    @State var currentTrack: Track?
    
    @State var tabBarVisible = false
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
                            .bold()
                            .font(.body)
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
                .toolbar(tabBarVisible ? .visible : .hidden, for: .tabBar)
                .onExitCommand {
                    tabBarVisible = true
                }
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
            tabBarVisible = isPlaying
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.trackChange)) { _ in
            currentTrack = AudioPlayer.current.nowPlaying
        }
    }
}

#Preview {
    NowPlayingView()
}
