//
//  VolumeSlider.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AFPlaybackKit

struct VolumeSlider: View {
    @State var volume = Double(AudioPlayer.current.volume) * 100
    @State var isDragging: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: "speaker.fill")
                .onTapGesture {
                    volume = 0.0
                }
            Slider(percentage: $volume, dragging: $isDragging)
            Image(systemName: "speaker.wave.3.fill")
                .onTapGesture {
                    volume = 100.0
                }
        }
        .dynamicTypeSize(isDragging ? .xLarge : .medium)
        .frame(height: 0)
        .animation(.easeInOut, value: isDragging)
        .onChange(of: volume) {
            if isDragging {
                AudioPlayer.current.setVolume(Float(volume / 100))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.volumeChange), perform: { _ in
            if !isDragging {
                withAnimation {
                    volume = Double(AudioPlayer.current.volume) * 100
                }
            }
        })
    }
}
