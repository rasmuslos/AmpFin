//
//  PlaybackIndicator.swift
//  iOS
//
//  Created by Rasmus Krämer on 14.01.24.
//

import SwiftUI
import AFBase
import AFPlayback

struct PlaybackIndicator<Placeholder: View>: View {
    let track: Track
    let placeholder: Placeholder
    
    @State var isActive: Bool
    @State var isPlaying: Bool
    
    init(track: Track, @ViewBuilder placeholder: () -> Placeholder) {
        self.track = track
        self.placeholder = placeholder()
        
        _isActive = State(initialValue: AudioPlayer.current.nowPlaying == track)
        _isPlaying = State(initialValue: AudioPlayer.current.isPlaying())
    }
    
    var body: some View {
        Group {
            if isActive {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .symbolEffect(.variableColor.iterative, isActive: isPlaying)
            } else {
                placeholder
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.trackChange)) { _ in
            withAnimation {
                isActive = AudioPlayer.current.nowPlaying == track
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPause)) { _ in
            isPlaying = AudioPlayer.current.isPlaying()
        }
    }
}

extension PlaybackIndicator where Placeholder == EmptyView {
    init(track: Track) {
        self.init(track: track) {
            EmptyView()
        }
    }
}

#Preview {
    PlaybackIndicator(track: Track.fixture) {
        Color.red
    }
}
