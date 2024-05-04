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
        
        @State private var volume = Double(AudioPlayer.current.volume) * 100
        
        var body: some View {
            HStack {
                Button {
                    AudioPlayer.current.volume = 0
                } label: {
                    Label("mute", systemImage: "speaker.fill")
                        .labelStyle(.iconOnly)
                }
                
                Slider(percentage: $volume, dragging: $dragging)
                
                Button {
                    AudioPlayer.current.volume = 1
                } label: {
                    Label("fullVolume", systemImage: "speaker.wave.3.fill")
                        .labelStyle(.iconOnly)
                }
            }
            .dynamicTypeSize(dragging ? .xLarge : .medium)
            .frame(height: 0)
            .animation(.easeInOut, value: dragging)
            .onChange(of: volume) {
                if dragging {
                    AudioPlayer.current.volume = Float(volume / 100)
                }
            }
            // because apple makes stupid software i guess
            .onReceive(AVAudioSession.sharedInstance().publisher(for: \.outputVolume), perform: { value in
                if !dragging && AudioPlayer.current.source == .local {
                    withAnimation {
                        volume = Double(value) * 100
                    }
                }
            })
        }
    }
}
