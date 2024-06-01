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
        
        private var lyricsButton: some View {
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
        private var queueButton: some View {
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
            HStack {
                if AudioPlayer.current.source == .local {
                    if compactLayout {
                        Spacer()
                        
                        lyricsButton
                            .frame(width: 44)
                        
                        Spacer()
                        
                        AirPlayPicker()
                            .frame(width: 44)
                        
                        Spacer()
                        
                        queueButton
                            .frame(width: 44)
                        
                        Spacer()
                    } else if horizontalSizeClass == .regular {
                        AirPlayPicker()
                            .frame(width: 25)
                        
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

extension NowPlaying {
    #if os(visionOS)
    typealias AirPlayPicker = EmptyView
    #else
    struct AirPlayPicker: UIViewRepresentable {
        func makeUIView(context: Context) -> UIView {
            let routePickerView = AVRoutePickerView()
            routePickerView.backgroundColor = UIColor.clear
            routePickerView.activeTintColor = UIColor(Color.accentColor)
            routePickerView.tintColor = UIColor(Color.white.opacity(0.6))
            
            return routePickerView
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {}
    }
    #endif
}
