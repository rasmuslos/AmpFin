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
        @Environment(ViewModel.self) private var viewModel
        
        let compact: Bool
        
        var body: some View {
            VStack(spacing: 0) {
                ProgressSlider(compact: compact)
                ControlButtons(compact: compact)
                
                VolumeSlider(dragging: .init(get: { viewModel.volumeDragging }, set: { viewModel.volumeDragging = $0; viewModel.controlsDragging = $0 }))
                VolumePicker()
                    .hidden()
                    .frame(height: 0)
            }
        }
    }
}

private struct ProgressSlider: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let compact: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            NowPlaying.Slider(percentage: .init(get: { viewModel.displayedProgress }, set: { viewModel.setPosition(percentage: $0) }),
                   dragging: .init(get: { viewModel.seekDragging }, set: { viewModel.seekDragging = $0; viewModel.controlsDragging = $0 }))
            .frame(height: 10)
            .padding(.bottom, compact ? 2 : 4)
            
            HStack(spacing: 0) {
                Group {
                    if viewModel.buffering {
                        ProgressView()
                            .scaleEffect(0.5)
                            .tint(.white)
                    } else {
                        Text(Duration.seconds(viewModel.currentTime).formatted(.time(pattern: .minuteSecond)))
                    }
                }
                .frame(width: 64, alignment: .leading)
                
                Spacer()
                
                Button {
                    viewModel.mediaInfoToggled.toggle()
                } label: {
                    Text(viewModel.qualityText ?? String(""))
                        .font(.footnote.smallCaps())
                        .foregroundStyle(.primary)
                        .padding(.vertical, compact ? 1 : 2)
                        .padding(.horizontal, compact ? 12 : 8)
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 4))
                        .opacity(viewModel.qualityText == nil ? 0 : 1)
                }
                Spacer()
                
                Text(Duration.seconds(AudioPlayer.current.duration).formatted(.time(pattern: .minuteSecond)))
                    .frame(width: 64, alignment: .trailing)
            }
            .font(.footnote.smallCaps())
            .foregroundStyle(.thinMaterial)
        }
    }
}
private struct ControlButtons: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let compact: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                AudioPlayer.current.rewind()
            } label: {
                Label("playback.back", systemImage: "backward.fill")
                    .labelStyle(.iconOnly)
                    .symbolEffect(.bounce.up, value: viewModel.notifyBackwards)
                    .font(.system(size: 32))
            }
            .modifier(HoverEffectModifier())
            
            Button {
                AudioPlayer.current.playing.toggle()
            } label: {
                Label("playback.toggle", systemImage: viewModel.playing ? "pause.fill" : "play.fill")
                    .labelStyle(.iconOnly)
                    .contentTransition(.symbolEffect(.replace.byLayer.downUp))
            }
            .frame(width: 52, height: 52)
            .font(.system(size: 48))
            .modifier(HoverEffectModifier())
            .padding(.horizontal, 50)
            
            Button {
                AudioPlayer.current.advance()
            } label: {
                Label("playback.next", systemImage: "forward.fill")
                    .labelStyle(.iconOnly)
                    .symbolEffect(.bounce.up, value: viewModel.notifyForwards)
                    .font(.system(size: 32))
            }
            .modifier(HoverEffectModifier())
        }
        .foregroundStyle(.primary)
        .padding(.top, compact ? 40 : 44)
        .padding(.bottom, compact ? 60 : 68)
    }
}

private struct VolumePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: CGRect.zero)
        return volumeView
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
