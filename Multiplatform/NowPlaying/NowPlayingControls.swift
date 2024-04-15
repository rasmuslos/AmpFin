//
//  NowPlayingView+Controls.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import MediaPlayer
import AFBase
import AFPlayback

struct NowPlayingControls: View {
    var compact: Bool = false
    
    @Binding var controlsDragging: Bool
    
    @State private var quality: String?
    
    @State private var seekDragging = false
    @State private var volumeDragging = false
    @State private var draggedPercentage = 0.0
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var playedPercentage: Double {
        (AudioPlayer.current.currentTime / AudioPlayer.current.duration) * 100
    }
    
    var body: some View {
        VStack {
            VStack {
                Slider(
                    percentage: .init(get: { seekDragging ? draggedPercentage : playedPercentage }, set: {
                        draggedPercentage = $0
                        AudioPlayer.current.currentTime = AudioPlayer.current.duration * ($0 / 100)
                    }),
                    dragging: .init(get: { seekDragging }, set: {
                        seekDragging = $0
                        controlsDragging = $0
                    }))
                .frame(height: 10)
                .padding(.bottom, compact ? 3 : 10)
                
                HStack {
                    Group {
                        if AudioPlayer.current.buffering {
                            ProgressView()
                                .scaleEffect(0.5)
                        } else {
                            Text(Duration.seconds(AudioPlayer.current.currentTime).formatted(.time(pattern: .minuteSecond)))
                        }
                    }
                    .frame(width: 65, alignment: .leading)
                    
                    if let quality = quality {
                        Spacer()
                        
                        Text(quality)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .padding(.vertical, compact ? 1 : 4)
                            .padding(.horizontal, compact ? 10 : 8)
                            .background(.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    Spacer()
                    
                    Text(Duration.seconds(AudioPlayer.current.duration).formatted(.time(pattern: .minuteSecond)))
                        .frame(width: 65, alignment: .trailing)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            HStack {
                Group {
                    Button {
                        withAnimation {
                            AudioPlayer.current.backToPreviousItem()
                        }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 30))
                    }
                    Button {
                        AudioPlayer.current.playing = !AudioPlayer.current.playing
                    } label: {
                        Image(systemName: AudioPlayer.current.playing ? "pause.fill" : "play.fill")
                            .frame(width: 50, height:50)
                            .font(.system(size: 47))
                            .padding(.horizontal, 50)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    Button {
                        withAnimation {
                            AudioPlayer.current.advanceToNextTrack()
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 30))
                    }
                }
                .foregroundStyle(.primary)
            }
            .padding(.top, compact ? 20 : 35)
            .padding(.bottom, compact ? 40 : 65)
            
            // The first view is the visible slider, the second one is there to hide the iOS indicator (10/10 hack)
            VolumeSlider(dragging: .init(get: { volumeDragging }, set: {
                volumeDragging = $0
                controlsDragging = $0
            }))
            VolumeView()
                .frame(width: 0, height: 0)
        }
        .onChange(of: AudioPlayer.current.nowPlaying) { fetchQuality() }
        .onAppear(perform: fetchQuality)
    }
}


// MARK: Helper

extension NowPlayingControls {
    private func fetchQuality() {
        Task.detached {
            if let data = await AudioPlayer.current.getTrackData() {
                withAnimation {
                    if data.1 == 0 {
                        quality = data.0.uppercased()
                    } else {
                        quality = "\(data.0.uppercased()) \(data.1)"
                    }
                }
            } else {
                quality = nil
            }
        }
    }
}

extension NowPlayingControls {
    struct VolumeView: UIViewRepresentable {
        func makeUIView(context: Context) -> MPVolumeView {
            let volumeView = MPVolumeView(frame: CGRect.zero)
            volumeView.alpha = 0.001
            
            return volumeView
        }
        
        func updateUIView(_ uiView: MPVolumeView, context: Context) {}
    }
}
