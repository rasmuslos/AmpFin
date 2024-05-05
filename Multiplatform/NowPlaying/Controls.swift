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

extension NowPlaying {
    struct Controls: View {
        let compact: Bool
        
        @Binding var controlsDragging: Bool
        
        @State private var trackDataToggled = false
        @State private var trackData: Track.TrackData? = nil
        
        @State private var seekDragging = false
        @State private var volumeDragging = false
        @State private var draggedPercentage = 0.0
        
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        private var playedPercentage: Double {
            (AudioPlayer.current.currentTime / AudioPlayer.current.duration) * 100
        }
        
        private var qualityText: String? {
            if let trackData = trackData {
                var result = [String]()
                
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 0
                formatter.usesGroupingSeparator = true
                
                if trackDataToggled && (trackData.bitDepth != nil || trackData.sampleRate != nil) {
                    if let bitDepth = trackData.bitDepth {
                        result.append(formatter.string(from: .init(value: bitDepth))!)
                    }
                    if let sampleRate = trackData.sampleRate {
                        result.append(formatter.string(from: .init(value: sampleRate))!)
                    }
                } else {
                    if let codec = trackData.codec {
                        result.append(codec.uppercased())
                    }
                    if let bitrate = trackData.bitrate {
                        result.append(formatter.string(from: .init(value: bitrate / 1000))!)
                    }
                }
                
                return result.joined(separator: " - ")
            }
            
            return nil
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
                    .padding(.bottom, compact ? 3 : 5)
                    
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
                        
                        if let qualityText = qualityText {
                            Spacer()
                            
                            Button {
                                trackDataToggled.toggle()
                            } label: {
                                Text(qualityText)
                                    .font(.caption2)
                                    .foregroundStyle(.primary)
                                    .padding(.vertical, compact ? 1 : 4)
                                    .padding(.horizontal, compact ? 10 : 8)
                                    .background(.tertiary)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
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
                            Label("playback.back", systemImage: "backward.fill")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 30))
                        }
                        .modifier(ButtonHoverEffectModifier())
                        
                        Button {
                            AudioPlayer.current.playing = !AudioPlayer.current.playing
                        } label: {
                            Label("playback.toggle", systemImage: AudioPlayer.current.playing ? "pause.fill" : "play.fill")
                                .labelStyle(.iconOnly)
                                .frame(width: 50, height:50)
                                .font(.system(size: 47))
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .modifier(ButtonHoverEffectModifier())
                        .padding(.horizontal, 50)
                        
                        Button {
                            withAnimation {
                                AudioPlayer.current.advanceToNextTrack()
                            }
                        } label: {
                            Label("playback.next", systemImage: "forward.fill")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 30))
                        }
                        .modifier(ButtonHoverEffectModifier())
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
                VolumePicker()
                    .frame(width: 0, height: 0)
            }
            .onChange(of: AudioPlayer.current.nowPlaying) { fetchQuality() }
            .onAppear(perform: fetchQuality)
        }
        
        private func fetchQuality() {
            Task.detached {
                if let trackData = await AudioPlayer.current.getTrackData() {
                    self.trackData = trackData
                    trackDataToggled = trackData.lossless ?? false
                } else {
                    trackData = nil
                }
            }
        }
    }
}

extension NowPlaying {
    struct VolumePicker: UIViewRepresentable {
        func makeUIView(context: Context) -> MPVolumeView {
            let volumeView = MPVolumeView(frame: CGRect.zero)
            volumeView.alpha = 0.001
            
            return volumeView
        }
        
        func updateUIView(_ uiView: MPVolumeView, context: Context) {}
    }
}
