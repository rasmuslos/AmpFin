//
//  VolumeSlider.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AFPlayback
import AVKit

extension NowPlaying {
    struct VolumeSlider: View {
        @Binding var dragging: Bool
        
        @State private var volume = Double(AudioPlayer.current.volume)
        
        var body: some View {
            HStack {
                Button {
                    AudioPlayer.current.volume = 0
                } label: {
                    Label("mute", systemImage: "speaker.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                
                Slider(percentage: $volume, dragging: $dragging)
                
                Button {
                    AudioPlayer.current.volume = 1
                } label: {
                    Label("fullVolume", systemImage: "speaker.wave.3.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
            }
            .dynamicTypeSize(dragging ? .xLarge : .medium)
            .frame(height: 0)
            .animation(.easeInOut, value: dragging)
            .onChange(of: AudioPlayer.current.volume) {
                volume = Double($1)
            }
            .onChange(of: dragging) {
                if $1 == false {
                    AudioPlayer.current.volume = Float(volume)
                }
            }
        }
    }
}
