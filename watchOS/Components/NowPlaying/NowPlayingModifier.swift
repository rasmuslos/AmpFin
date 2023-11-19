//
//  NowPlayingModifier.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import MusicKit
import WatchKit
import ConnectivityKit

struct NowPlayingModifier: ViewModifier {
    // TODO: make this work the app, too
    @State var playing: Bool = AudioPlayer.shared.isPlaying()
    @State var nowPlayingSheetPresented = false
    @State var optionsPresented = false
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        nowPlayingSheetPresented.toggle()
                    } label: {
                        Image(systemName: "waveform")
                            .symbolEffect(.variableColor.dimInactiveLayers.iterative, isActive: playing)
                    }
                }
            }
            .sheet(isPresented: $nowPlayingSheetPresented, content: {
                NowPlayingView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                optionsPresented.toggle()
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                    .sheet(isPresented: $optionsPresented, content: {
                        OptionsSheet()
                    })
            })
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPause), perform: { _ in
                playing = AudioPlayer.shared.isPlaying()
            })
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.trackChange), perform: { _ in
                optionsPresented = false
            })
            .onReceive(NotificationCenter.default.publisher(for: ConnectivityKit.nowPlayingActivityStarted)) { _ in
                nowPlayingSheetPresented = true
            }
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playbackStarted), perform: { _ in
                nowPlayingSheetPresented = true
            })
    }
}

#Preview {
    NavigationStack {
        Text(":)")
            .modifier(NowPlayingModifier())
    }
}
