//
//  NowPlayingButtons.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback
import AVKit

extension NowPlaying {
    struct Buttons: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(ViewModel.self) private var viewModel
        
        private var isCompact: Bool {
            horizontalSizeClass == .compact
        }
        
        private var routeIcon: String {
            switch viewModel.outputRoute.port {
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
        
        @ViewBuilder private var lyricsButton: some View {
            Button {
                viewModel.selectTab(.lyrics)
            } label: {
                Label("lyrics", systemImage: viewModel.currentTab == .lyrics ? "text.bubble.fill" : "text.bubble")
                    .labelStyle(.iconOnly)
                    .contentShape(.rect)
            }
            .foregroundStyle(viewModel.currentTab == .lyrics ? .thickMaterial : .thinMaterial)
            .animation(.none, value: viewModel.currentTab)
            .buttonStyle(.plain)
            .modifier(HoverEffectModifier(padding: 4))
            .padding(12)
            .onTapGesture {
                viewModel.selectTab(.lyrics)
            }
            .padding(-12)
        }
        @ViewBuilder private var queueButton: some View {
            Menu {
                Toggle("shuffle", systemImage: "shuffle", isOn: .init(get: { viewModel.shuffled }, set: { AudioPlayer.current.shuffled = $0 }))
                
                Menu {
                    ForEach(RepeatMode.allCases.filter { AudioPlayer.current.infiniteQueue != nil || $0 != .infinite }) { repeatMode in
                        Toggle(isOn: .init(get: { viewModel.repeatMode == repeatMode }, set: { _ in AudioPlayer.current.repeatMode = repeatMode })) {
                            switch repeatMode {
                                case .none:
                                    Label("repeat.none", systemImage: "slash.circle")
                                case .queue:
                                    Label("repeat.queue", systemImage: "repeat")
                                case .track:
                                    Label("repeat.track", systemImage: "repeat.1")
                                case .infinite:
                                    Label("repeat.infinite", systemImage: "infinity")
                            }
                        }
                    }
                } label: {
                    Label("repeat", systemImage: "repeat")
                }
            } label: {
                Label("queue", systemImage: "list.dash")
                    .labelStyle(.iconOnly)
                    .contentShape(.rect)
            } primaryAction: {
                viewModel.selectTab(.queue)
            }
            .buttonStyle(SymbolButtonStyle(active: viewModel.currentTab == .queue))
            .modifier(HoverEffectModifier(padding: 4))
            .padding(12)
            .onTapGesture {
                viewModel.selectTab(.queue)
            }
            .padding(-12)
        }
        
        var body: some View {
            HStack(alignment: .center) {
                if viewModel.source == .local {
                    if isCompact {
                        Spacer()
                        
                        lyricsButton
                            .frame(width: 75)
                        
                        Spacer()
                        
                        Button {
                            AirPlay.shared.presentPicker()
                        } label: {
                            Label("output", systemImage: routeIcon)
                                .labelStyle(.iconOnly)
                                .contentShape(.rect)
                                .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                        }
                        .buttonStyle(SymbolButtonStyle(active: false))
                        .modifier(HoverEffectModifier(padding: 4))
                        .frame(width: 75)
                        .padding(12)
                        .onTapGesture {
                            AirPlay.shared.presentPicker()
                        }
                        .padding(-12)
                        .overlay(alignment: .bottom) {
                            if viewModel.outputRoute.showLabel {
                                Text(viewModel.outputRoute.name)
                                    .lineLimit(1)
                                    .font(.caption2.smallCaps())
                                    .foregroundStyle(.thinMaterial)
                                    .offset(y: 12)
                                    .fixedSize()
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
                                    .contentShape(.rect)
                                    .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                            }
                            .buttonStyle(SymbolButtonStyle(active: false))
                            .modifier(HoverEffectModifier(padding: 4))
                            
                            if viewModel.outputRoute.showLabel {
                                Text(viewModel.outputRoute.name)
                                    .lineLimit(1)
                                    .font(.caption.smallCaps())
                                    .foregroundStyle(.thinMaterial)
                            }
                        }
                        
                        Spacer()
                        
                        lyricsButton
                            .padding(.horizontal, 16)
                        queueButton
                    }
                } else if viewModel.source == .jellyfinRemote {
                    Spacer()
                    
                    lyricsButton
                    
                    Spacer()
                    
                    Button {
                        AudioPlayer.current.shuffled.toggle()
                    } label: {
                        Label("shuffle", systemImage: "shuffle")
                            .labelStyle(.iconOnly)
                            .contentShape(.rect)
                    }
                    .buttonStyle(SymbolButtonStyle(active: viewModel.shuffled))
                    .padding(12)
                    .onTapGesture {
                        AudioPlayer.current.shuffled.toggle()
                    }
                    .padding(-12)
                    
                    Spacer()
                    
                    Button {
                        AudioPlayer.current.repeatMode = viewModel.repeatMode.next
                    } label: {
                        Label("repeat", systemImage: "repeat\(viewModel.repeatMode == .track ? ".1" : "")")
                            .labelStyle(.iconOnly)
                            .contentShape(.rect)
                    }
                    .buttonStyle(SymbolButtonStyle(active: viewModel.repeatMode != .none))
                    .padding(12)
                    .onTapGesture {
                        AudioPlayer.current.repeatMode = viewModel.repeatMode.next
                    }
                    .padding(-12)
                    
                    Spacer()
                }
            }
            .bold()
            .font(.system(size: 20))
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
