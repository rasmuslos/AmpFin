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
    
    init(track: Track, @ViewBuilder placeholder: () -> Placeholder) {
        self.track = track
        self.placeholder = placeholder()
    }
    
    var body: some View {
        Group {
            if AudioPlayer.current.nowPlaying == track {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .symbolEffect(.variableColor.iterative, isActive: AudioPlayer.current.playing)
            } else {
                placeholder
            }
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
