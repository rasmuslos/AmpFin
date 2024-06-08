//
//  NowPlayingView+Controls.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import MediaPlayer
import AmpFinKit
import AFPlayback

extension NowPlaying {
    struct Controls: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let compact: Bool
        
        @Binding var controlsDragging: Bool
        
        @State private var mediaInfoToggled = false
        @State private var mediaInfo: Track.MediaInfo? = nil
        
        @State private var seekDragging = false
        @State private var volumeDragging = false
        @State private var draggedPercentage = 0.0
        
        @State private var animateBackward = false
        @State private var animateForward = false
        
        private var playedPercentage: Double { AudioPlayer.current.currentTime / AudioPlayer.current.duration }
        
        private var qualityText: String? {
            if let mediaInfo = mediaInfo {
                var result = [String]()
                
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 0
                formatter.usesGroupingSeparator = true
                
                if mediaInfoToggled && (mediaInfo.bitDepth != nil || mediaInfo.sampleRate != nil) {
                    if let bitDepth = mediaInfo.bitDepth {
                        result.append(formatter.string(from: .init(value: bitDepth))!)
                    }
                    if let sampleRate = mediaInfo.sampleRate {
                        result.append(formatter.string(from: .init(value: sampleRate))!)
                    }
                } else {
                    if let codec = mediaInfo.codec {
                        result.append(codec.uppercased())
                    }
                    if let bitrate = mediaInfo.bitrate {
                        result.append(formatter.string(from: .init(value: bitrate / 1000))!)
                    }
                }
                
                if result.isEmpty {
                    return nil
                }
                
                return result.joined(separator: " - ")
            }
            
            return nil
        }
        
        var body: some View {
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Slider(
                        percentage: .init(get: { seekDragging ? draggedPercentage : playedPercentage }, set: {
                            draggedPercentage = $0
                            AudioPlayer.current.currentTime = AudioPlayer.current.duration * $0
                        }),
                        dragging: .init(get: { seekDragging }, set: {
                            seekDragging = $0
                            controlsDragging = $0
                        }))
                    .frame(height: 10)
                    .padding(.bottom, compact ? 2 : 4)
                    
                    HStack(spacing: 0) {
                        Group {
                            if AudioPlayer.current.buffering {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .tint(.white)
                            } else {
                                Text(Duration.seconds(AudioPlayer.current.currentTime).formatted(.time(pattern: .minuteSecond)))
                            }
                        }
                        .frame(width: 64, alignment: .leading)
                        
                        Spacer()
                        
                        Button {
                            mediaInfoToggled.toggle()
                        } label: {
                            Text(qualityText ?? String(""))
                                .font(.footnote.smallCaps())
                                .foregroundStyle(.primary)
                                .padding(.vertical, compact ? 1 : 2)
                                .padding(.horizontal, compact ? 12 : 8)
                                .background(.ultraThinMaterial)
                                .clipShape(.rect(cornerRadius: 4))
                                .opacity(qualityText == nil ? 0 : 1)
                        }
                        Spacer()
                        
                        Text(Duration.seconds(AudioPlayer.current.duration).formatted(.time(pattern: .minuteSecond)))
                            .frame(width: 64, alignment: .trailing)
                    }
                    .font(.footnote.smallCaps())
                    .foregroundStyle(.thinMaterial)
                }
                
                HStack(spacing: 0) {
                    Button {
                        withAnimation {
                            animateBackward.toggle()
                            AudioPlayer.current.backToPreviousItem()
                        }
                    } label: {
                        Label("playback.back", systemImage: "backward.fill")
                            .labelStyle(.iconOnly)
                            .symbolEffect(.bounce.up, value: animateBackward)
                            .font(.system(size: 32))
                    }
                    .modifier(HoverEffectModifier())
                    .sensoryFeedback(.decrease, trigger: animateBackward)
                    
                    Button {
                        AudioPlayer.current.playing.toggle()
                    } label: {
                        Label("playback.toggle", systemImage: AudioPlayer.current.playing ? "pause.fill" : "play.fill")
                            .labelStyle(.iconOnly)
                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                    }
                    .frame(width: 52, height: 52)
                    .font(.system(size: 48))
                    .modifier(HoverEffectModifier())
                    .padding(.horizontal, 50)
                    .sensoryFeedback(.selection, trigger: AudioPlayer.current.playing)
                    
                    Button {
                        withAnimation {
                            animateForward.toggle()
                            AudioPlayer.current.advanceToNextTrack()
                        }
                    } label: {
                        Label("playback.next", systemImage: "forward.fill")
                            .labelStyle(.iconOnly)
                            .symbolEffect(.bounce.up, value: animateForward)
                            .font(.system(size: 32))
                    }
                    .modifier(HoverEffectModifier())
                    .sensoryFeedback(.increase, trigger: animateForward)
                }
                .foregroundStyle(.primary)
                .padding(.top, compact ? 20 : 44)
                .padding(.bottom, compact ? 40 : 68)
                
                // The first view is the visible slider, the second one is there to hide the iOS indicator (10/10 hack)
                VolumeSlider(dragging: .init(get: { volumeDragging }, set: {
                    volumeDragging = $0
                    controlsDragging = $0
                }))
                VolumePicker()
                    .frame(width: 0, height: 0)
            }
            .task(id: AudioPlayer.current.nowPlaying) {
                await fetchQuality()
            }
        }
        
        private func fetchQuality() async {
            if let mediaInfo = await AudioPlayer.current.mediaInfo {
                self.mediaInfo = mediaInfo
                mediaInfoToggled = mediaInfo.lossless ?? false
            } else {
                mediaInfo = nil
            }
        }
    }
}


private struct VolumePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: CGRect.zero)
        volumeView.alpha = 0.001
        
        return volumeView
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
