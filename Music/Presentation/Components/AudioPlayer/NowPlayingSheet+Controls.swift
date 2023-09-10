//
//  NowPlayingSheet+Controls.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AVKit

extension NowPlayingSheet {
    struct Controls: View {
        @Binding var playing: Bool
        @Binding var currentTab: Tab {
            didSet {
                queueTabActive = currentTab == .queue
            }
        }
        
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
                        Text(Duration.seconds(currentTime).formatted(.time(pattern: .minuteSecond)))
                        /*
                         Spacer()
                         Text("FLAC 1453")
                         .foregroundStyle(.secondary)
                         */
                        Spacer()
                        Text(Duration.seconds(duration).formatted(.time(pattern: .minuteSecond)))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                HStack {
                    Group {
                        Button {
                            AudioPlayer.shared.playPreviousTrack()
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
                            AudioPlayer.shared.playNextTrack()
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
                    Button {
                        setActiveTab(.lyrics)
                    } label: {
                        Image(systemName: currentTab == .lyrics ? "text.bubble.fill" : "text.bubble")
                    }
                    .foregroundStyle(currentTab == .lyrics ? .primary : .secondary)
                    
                    Spacer()
                    AirPlayView()
                        .frame(width: 45)
                        .padding(.vertical, -100)
                    
                    Spacer()
                    Button {
                        setActiveTab(.queue)
                    } label: {
                        Image(systemName: "list.dash")
                    }
                    .buttonStyle(SymbolButtonStyle(active: $queueTabActive))
                }
                .bold()
                .font(.system(size: 20))
                .frame(height: 45)
                .padding(.horizontal, 45)
                .padding(.top, 35)
                .padding(.bottom, 40)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.PositionUpdated), perform: { _ in
                withAnimation {
                    duration = AudioPlayer.shared.duration()
                    currentTime = AudioPlayer.shared.currentTime()
                    playedPercentage = (currentTime / duration) * 100
                }
            })
        }
        
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
