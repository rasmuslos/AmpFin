//
//  VolumeSlider.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AFPlayback

internal extension NowPlaying {
    struct VolumeSlider: View {
        @Binding var dragging: Bool
        
        @State private var volume = Double(AudioPlayer.current.volume)
        
        var body: some View {
            HStack {
                Slider(percentage: .init() { volume } set: { AudioPlayer.current.volume = Float($0) }, dragging: $dragging)
            }
            .foregroundStyle(.thinMaterial)
            .saturation(1.6)
            .animation(.easeInOut, value: dragging)
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.volumeDidChangeNotification)) { _ in
                if !dragging {
                    volume = Double(AudioPlayer.current.volume)
                }
            }
        }
    }
}
