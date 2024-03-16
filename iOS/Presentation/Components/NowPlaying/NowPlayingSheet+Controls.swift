//
//  NowPlayingSheet+Controls.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AVKit
import MediaPlayer
import AFBase
import AFPlayback

extension NowPlayingSheet {
    struct Controls: View {
        @Binding var playing: Bool
        @Binding var currentTab: Tab {
            didSet {
                queueTabActive = currentTab == .queue
            }
        }
        
        @State private var buffering: Bool = AudioPlayer.current.buffering
        @State private var quality: String?
        
        @State private var duration: Double = AudioPlayer.current.duration()
        @State private var currentTime: Double = AudioPlayer.current.currentTime()
        @State private var playedPercentage: Double = (AudioPlayer.current.currentTime() / AudioPlayer.current.duration()) * 100
        
        @State private var dragging = false
        @State private var queueTabActive = false
        
        var body: some View {
            VStack {
                VStack {
                    Slider(percentage: $playedPercentage, dragging: $dragging, onEnded: {
                        AudioPlayer.current.seek(seconds: duration * (playedPercentage / 100))
                    })
                    .frame(height: 10)
                    .padding(.bottom, 10)
                    
                    HStack {
                        Group {
                            if buffering {
                                ProgressView()
                                    .scaleEffect(0.5)
                            } else {
                                Text(Duration.seconds(currentTime).formatted(.time(pattern: .minuteSecond)))
                            }
                        }
                        .frame(width: 65, alignment: .leading)
                        
                        if let quality = quality {
                            Spacer()
                            Text(quality)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        Spacer()
                        
                        Text(Duration.seconds(duration).formatted(.time(pattern: .minuteSecond)))
                            .frame(width: 65, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                HStack {
                    Group {
                        Button {
                            AudioPlayer.current.backToPreviousItem()
                        } label: {
                            Image(systemName: "backward.fill")
                        }
                        Button {
                            AudioPlayer.current.setPlaying(!AudioPlayer.current.isPlaying())
                        } label: {
                            Image(systemName: playing ? "pause.fill" : "play.fill")
                                .frame(height: 50)
                                .font(.system(size: 47))
                                .padding(.horizontal, 50)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        Button {
                            AudioPlayer.current.advanceToNextTrack()
                        } label: {
                            Image(systemName: "forward.fill")
                        }
                    }
                    .font(.system(size: 34))
                    .foregroundStyle(.primary)
                }
                .padding(.top, 35)
                .padding(.bottom, 65)
                
                // The first view is the visible slider, the second one is there to hide the iOS indicator (10/10 hack)
                VolumeSlider()
                VolumeView()
                    .frame(width: 0, height: 0)
                
                HStack {
                    Spacer()
                    
                    if AudioPlayer.current.source == .local {
                        // disabled until lyrics are fully supported by the stable server
                        #if DEBUG
                        Button {
                            setActiveTab(.lyrics)
                        } label: {
                            Image(systemName: currentTab == .lyrics ? "text.bubble.fill" : "text.bubble")
                        }
                        .foregroundStyle(currentTab == .lyrics ? .primary : .secondary)
                        
                        Spacer()
                        #endif
                        
                        AirPlayView()
                            .frame(width: 45)
                        
                        Spacer()
                        
                        Button {
                            setActiveTab(.queue)
                        } label: {
                            Image(systemName: "list.dash")
                        }
                        .buttonStyle(SymbolButtonStyle(active: queueTabActive))
                    } else if AudioPlayer.current.source == .jellyfinRemote {
                        Button {
                            AudioPlayer.current.shuffle(!AudioPlayer.current.shuffled)
                        } label: {
                            Image(systemName: "shuffle")
                        }
                        .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.shuffled))
                        
                        Spacer()
                        
                        Button {
                            if AudioPlayer.current.repeatMode == .none {
                                AudioPlayer.current.setRepeatMode(.queue)
                            } else if AudioPlayer.current.repeatMode == .queue {
                                AudioPlayer.current.setRepeatMode(.track)
                            } else if AudioPlayer.current.repeatMode == .track {
                                AudioPlayer.current.setRepeatMode(.none)
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
                    } else {
                        Button {
                            setActiveTab(currentTab == .cover ? .queue : .cover)
                        } label: {
                            Image(systemName: "command")
                        }
                        .buttonStyle(SymbolButtonStyle(active: currentTab == .queue))
                    }
                    
                    Spacer()
                }
                .bold()
                .font(.system(size: 20))
                .frame(height: 45)
                .padding(.top, 35)
                .padding(.bottom, 40)
            }
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.positionUpdated), perform: { _ in
                withAnimation {
                    buffering = AudioPlayer.current.buffering
                    duration = AudioPlayer.current.duration()
                    currentTime = AudioPlayer.current.currentTime()
                    playedPercentage = (currentTime / duration) * 100
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.trackChange), perform: { _ in
                fetchQuality()
            })
            .onAppear(perform: fetchQuality)
        }
        
        // this has to be here for reasons that are beyond me
        func setActiveTab(_ tab: Tab) {
            withAnimation(.easeInOut(duration: 0.25)) {
                if currentTab == tab {
                    currentTab = .cover
                } else {
                    currentTab = tab
                }
            }
        }
    }
}

// MARK: Helper

extension NowPlayingSheet.Controls {
    func fetchQuality() {
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

// MARK: Airplay view

extension NowPlayingSheet {
    struct AirPlayView: UIViewRepresentable {
        func makeUIView(context: Context) -> UIView {
            let routePickerView = AVRoutePickerView()
            routePickerView.backgroundColor = UIColor.clear
            routePickerView.activeTintColor = UIColor(Color.accentColor)
            routePickerView.tintColor = UIColor(Color.secondary)
            
            return routePickerView
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {}
    }
    
    struct VolumeView: UIViewRepresentable {
        func makeUIView(context: Context) -> MPVolumeView {
            let volumeView = MPVolumeView(frame: CGRect.zero)
            volumeView.alpha = 0.001
            
            return volumeView
        }
        
        func updateUIView(_ uiView: MPVolumeView, context: Context) {}
    }
}
