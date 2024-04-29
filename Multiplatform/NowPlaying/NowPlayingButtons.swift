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

struct NowPlayingButtons: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Binding var currentTab: NowPlayingTab
    
    private var lyricsButton: some View {
        Button {
            setActiveTab(.lyrics)
        } label: {
            Image(systemName: currentTab == .lyrics ? "text.bubble.fill" : "text.bubble")
        }
        .foregroundStyle(currentTab == .lyrics ? .primary : .secondary)
    }
    private var queueButton: some View {
        Button {
            setActiveTab(.queue)
        } label: {
            Image(systemName: "list.dash")
        }
        .buttonStyle(SymbolButtonStyle(active: currentTab == .queue))
    }
    
    var body: some View {
        HStack {
            if AudioPlayer.current.source == .local {
                if horizontalSizeClass == .compact {
                    Spacer()
                    
                    lyricsButton
                    
                    Spacer()
                    
                    NowPlayingAirPlayView()
                        .frame(width: 45)
                    
                    Spacer()
                    
                    queueButton
                    
                    Spacer()
                } else if horizontalSizeClass == .regular {
                    NowPlayingAirPlayView()
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
                    Image(systemName: "shuffle")
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
                    if AudioPlayer.current.repeatMode == .track {
                        Image(systemName: "repeat.1")
                    } else if AudioPlayer.current.repeatMode == .none || AudioPlayer.current.repeatMode == .queue {
                        Image(systemName: "repeat")
                    }
                }
                .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none))
                
                Spacer()
                
                Button {
                    AudioPlayer.current.destroy()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(SymbolButtonStyle(active: false))
                
                Spacer()
            } else {
                Button {
                    setActiveTab(currentTab == .cover ? .queue : .cover)
                } label: {
                    Image(systemName: "command")
                }
                .buttonStyle(SymbolButtonStyle(active: currentTab == .queue))
            }
        }
        .bold()
        .font(.system(size: 20))
        .frame(height: 45)
    }
    
    func setActiveTab(_ tab: NowPlayingTab) {
        withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
            if currentTab == tab {
                currentTab = .cover
            } else {
                currentTab = tab
            }
        }
    }
}

struct NowPlayingAirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = UIColor.clear
        routePickerView.activeTintColor = UIColor(Color.accentColor)
        routePickerView.tintColor = UIColor(Color.white.opacity(0.6))
        
        return routePickerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
