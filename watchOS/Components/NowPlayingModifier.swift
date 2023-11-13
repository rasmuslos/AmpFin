//
//  NowPlayingModifier.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import MusicKit

struct NowPlayingModifier: ViewModifier {
    // TODO: make this work the app, too
    @State var playing: Bool = AudioPlayer.shared.isPlaying()
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: NavigationRoot.NowPlayingNavigationDestination()) {
                        Image(systemName: "waveform")
                            .symbolEffect(.variableColor.dimInactiveLayers.iterative, value: playing)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPause), perform: { _ in
                playing = AudioPlayer.shared.isPlaying()
            })
    }
}
