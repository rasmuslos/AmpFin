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
        
        @State private var counter = 0
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
                if !dragging {
                    volume = Double($1)
                }
            }
            .onChange(of: volume) {
                if dragging {
                    counter += 1
                    
                    if counter == 7 {
                        AudioPlayer.current.volume = Float(volume)
                        counter = 0
                    }
                }
            }
        }
    }
}
