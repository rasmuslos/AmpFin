//
//  NowPlayingButtons.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AVKit
import AFBase
import AFPlayback

extension NowPlaying {
    struct Buttons: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        @Binding var currentTab: Tab
        
        private var lyricsButton: some View {
            Button {
                setActiveTab(.lyrics)
            } label: {
                Label("lyrics", systemImage: currentTab == .lyrics ? "text.bubble.fill" : "text.bubble")
                    .labelStyle(.iconOnly)
            }
            .foregroundStyle(currentTab == .lyrics ? .primary : .secondary)
        }
        private var queueButton: some View {
            Button {
                setActiveTab(.queue)
            } label: {
                Label("queue", systemImage: "list.dash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(SymbolButtonStyle(active: currentTab == .queue))
        }
        
        var body: some View {
            HStack {
                if AudioPlayer.current.source == .local {
                    if horizontalSizeClass == .compact {
                        Spacer()
                        
                        lyricsButton
                            .frame(width: 45)
                        
                        Spacer()
                        
                        AirPlayPicker()
                            .frame(width: 45)
                        
                        Spacer()
                        
                        queueButton
                            .frame(width: 45)
                        
                        Spacer()
                    } else if horizontalSizeClass == .regular {
                        AirPlayPicker()
                            .frame(width: 25)
                        
                        Spacer()
                        
                        lyricsButton
                            .padding(.horizontal, 20)
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
                        AudioPlayer.current.destroy()
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
            .frame(height: 45)
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
