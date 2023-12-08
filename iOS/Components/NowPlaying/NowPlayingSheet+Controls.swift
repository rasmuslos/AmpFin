//
//  NowPlayingSheet+Controls.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AVKit
import MusicKit

extension NowPlayingSheet {
    struct Controls: View {
        @Binding var playing: Bool
        @Binding var currentTab: Tab {
            didSet {
                queueTabActive = currentTab == .queue
            }
        }
        
        @State var buffering: Bool = AudioPlayer.shared.buffering
        @State var quality: String?
        
        @State var duration: Double = AudioPlayer.shared.duration()
        @State var currentTime: Double = AudioPlayer.shared.currentTime()
        @State var playedPercentage: Double = (AudioPlayer.shared.currentTime() / AudioPlayer.shared.duration()) * 100
        
        @State var queueTabActive = false
        
        var body: some View {
            VStack {
                VStack {
                    Slider(percentage: $playedPercentage, dragging: .constant(false), onEnded: {
                        AudioPlayer.shared.seek(seconds: duration * (playedPercentage / 100))
                    })
                    .padding(.vertical, 10)
                    
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
                            AudioPlayer.shared.backToPreviousItem()
                        } label: {
                            Image(systemName: "backward.fill")
                        }
                        Button {
                            AudioPlayer.shared.setPlaying(!AudioPlayer.shared.isPlaying())
                        } label: {
                            Image(systemName: playing ? "pause.fill" : "play.fill")
                                .frame(height: 50)
                                .font(.system(size: 47))
                                .padding(.horizontal, 50)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        Button {
                            AudioPlayer.shared.advanceToNextTrack()
                        } label: {
                            Image(systemName: "forward.fill")
                        }
                    }
                    .font(.system(size: 34))
                    .foregroundStyle(.primary)
                }
                .padding(.top, 30)
                .padding(.bottom, 60)
                
                VolumeSlider()
                
                HStack {
                    // sometime when they are properly supported by the server
                    /*
                    Button {
                        setActiveTab(.lyrics)
                    } label: {
                        Image(systemName: currentTab == .lyrics ? "text.bubble.fill" : "text.bubble")
                    }
                    .foregroundStyle(currentTab == .lyrics ? .primary : .secondary)
                    .popoverTip(LyricsTip(), arrowEdge: .bottom)
                     */
                    
                    Spacer()
                    AirPlayView()
                        .frame(width: 45)
                    
                    Spacer()
                    Button {
                        setActiveTab(.queue)
                    } label: {
                        Image(systemName: "list.dash")
                    }
                    .buttonStyle(SymbolButtonStyle(active: queueTabActive))
                    
                    Spacer()
                }
                .bold()
                .font(.system(size: 20))
                .frame(height: 45)
                .padding(.horizontal, 45)
                .padding(.top, 35)
                .padding(.bottom, 40)
            }
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.positionUpdated), perform: { _ in
                withAnimation {
                    buffering = AudioPlayer.shared.buffering
                    duration = AudioPlayer.shared.duration()
                    currentTime = AudioPlayer.shared.currentTime()
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
            if let data = await AudioPlayer.shared.getTrackData() {
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
}
