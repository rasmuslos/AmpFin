//
//  NowPlayingButtons.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AVKit
import AmpFinKit
import AFPlayback

extension NowPlaying {
    struct Buttons: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        @Binding var currentTab: Tab
        
        private var compactLayout: Bool {
            horizontalSizeClass == .compact
        }
        
        private var routeIcon: String {
            switch AudioPlayer.current.outputPort {
                case .usbAudio:
                    "cable.connector"
                case .thunderbolt:
                    "bolt"
                case .lineOut:
                    "cable.coaxial"
                case .carAudio:
                    "car"
                case .airPlay:
                    "airplayaudio"
                case .HDMI, .displayPort:
                    "tv"
                case .bluetoothLE, .bluetoothHFP, .bluetoothA2DP:
                    "hifispeaker"
                case .headphones:
                    "headphones"
                default:
                    "airplayaudio"
            }
        }
        private var showRouteLabel: Bool {
            AudioPlayer.current.outputPort == .bluetoothLE || AudioPlayer.current.outputPort == .bluetoothHFP || AudioPlayer.current.outputPort == .bluetoothA2DP || AudioPlayer.current.outputPort == .carAudio || AudioPlayer.current.outputPort == .airPlay
        }
        
        @ViewBuilder private var lyricsButton: some View {
            Button {
                setActiveTab(.lyrics)
            } label: {
                Label("lyrics", systemImage: currentTab == .lyrics ? "text.bubble.fill" : "text.bubble")
                    .labelStyle(.iconOnly)
            }
            .foregroundStyle(currentTab == .lyrics ? .thickMaterial : .thinMaterial)
            .animation(.none, value: currentTab)
            .buttonStyle(.plain)
            .modifier(HoverEffectModifier(padding: 4))
        }
        @ViewBuilder private var queueButton: some View {
            Menu {
                Toggle("shuffle", systemImage: "shuffle", isOn: .init(get: { AudioPlayer.current.shuffled }, set: { AudioPlayer.current.shuffled = $0 }))
                
                Menu {
                    Button {
                        AudioPlayer.current.repeatMode = .none
                    } label: {
                        Label("repeat.none", systemImage: "slash.circle")
                    }
                    
                    Button {
                        AudioPlayer.current.repeatMode = .queue
                    } label: {
                        Label("repeat.queue", systemImage: "repeat")
                    }
                    
                    Button {
                        AudioPlayer.current.repeatMode = .track
                    } label: {
                        Label("repeat.track", systemImage: "repeat.1")
                    }
                } label: {
                    Label("repeat", systemImage: "repeat")
                }
            } label: {
                Label("queue", systemImage: "list.dash")
                    .labelStyle(.iconOnly)
            } primaryAction: {
                setActiveTab(.queue)
            }
            .buttonStyle(SymbolButtonStyle(active: currentTab == .queue))
            .modifier(HoverEffectModifier(padding: 4))
        }
        
        var body: some View {
            HStack(alignment: .center) {
                if AudioPlayer.current.source == .local {
                    if compactLayout {
                        Spacer()
                        
                        lyricsButton
                            .frame(width: 75)
                        
                        Spacer()
                        
                        Button {
                            AirPlay.shared.presentPicker()
                        } label: {
                            Label("output", systemImage: routeIcon)
                                .labelStyle(.iconOnly)
                                .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                        }
                        .buttonStyle(SymbolButtonStyle(active: false))
                        .modifier(HoverEffectModifier(padding: 4))
                        .frame(width: 75)
                        .overlay(alignment: .bottom) {
                            if showRouteLabel, let outputName = AVAudioSession.sharedInstance().currentRoute.outputs.first?.portName {
                                Text(outputName)
                                    .lineLimit(1)
                                    .font(.caption2)
                                    .foregroundStyle(.thinMaterial)
                                    .offset(y: 12)
                                    .fixedSize()
                                    .id(AudioPlayer.current.outputPort)
                            }
                        }
                        
                        Spacer()
                        
                        queueButton
                            .frame(width: 75)
                        
                        Spacer()
                    } else if horizontalSizeClass == .regular {
                        HStack(spacing: 4) {
                            Button {
                                AirPlay.shared.presentPicker()
                            } label: {
                                Label("output", systemImage: routeIcon)
                                    .labelStyle(.iconOnly)
                                    .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                            }
                            .buttonStyle(SymbolButtonStyle(active: false))
                            .modifier(HoverEffectModifier(padding: 4))
                            
                            if showRouteLabel, let outputName = AVAudioSession.sharedInstance().currentRoute.outputs.first?.portName {
                                Text(outputName)
                                    .lineLimit(1)
                                    .font(.caption)
                                    .foregroundStyle(.thinMaterial)
                                    .id(AudioPlayer.current.outputPort)
                            }
                        }
                        
                        Spacer()
                        
                        lyricsButton
                            .padding(.horizontal, 16)
                        queueButton
                    }
                } else if AudioPlayer.current.source == .jellyfinRemote {
                    Spacer()
                    
                    Button {
                        AudioPlayer.current.shuffled = !AudioPlayer.current.shuffled
                    } label: {
                        Label("shuffle", systemImage: "shuffle")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.shuffled))
                    
                    Spacer()
                    
                    Button {
                        if AudioPlayer.current.repeatMode == .none {
                            AudioPlayer.current.repeatMode = .queue
                        } else if AudioPlayer.current.repeatMode == .queue {
                            AudioPlayer.current.repeatMode = .track
                        } else if AudioPlayer.current.repeatMode == .track {
                            AudioPlayer.current.repeatMode = .none
                        }
                    } label: {
                        Label("repeat", systemImage: "repeat\(AudioPlayer.current.repeatMode == .track ? ".1" : "")")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none))
                    
                    Spacer()
                    
                    Button {
                        AudioPlayer.current.stopPlayback()
                    } label: {
                        Label("remote.stop", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(SymbolButtonStyle(active: false))
                    
                    Spacer()
                }
            }
            .bold()
            .font(.system(size: 20))
            .frame(height: 44)
        }
        
        private func setActiveTab(_ tab: Tab) {
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                if currentTab == tab {
                    currentTab = .cover
                } else {
                    currentTab = tab
                }
            }
        }
    }
}

private struct AirPlay {
    let routePickerView = AVRoutePickerView()
    
    private init() {}
    
    func presentPicker() {
        for view in routePickerView.subviews {
            guard let button = view as? UIButton else {
                continue
            }
            
            button.sendActions(for: .touchUpInside)
            break
        }
    }
    
    static let shared = AirPlay()
}
