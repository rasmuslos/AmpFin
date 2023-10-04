//
//  NowPlayingBar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

struct NowPlayingBarModifier: ViewModifier {
    @State var playing = AudioPlayer.shared.isPlaying()
    @State var currentTrack = AudioPlayer.shared.nowPlaying
    
    @State var nowPlayingSheetPresented = false
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let currentTrack = currentTrack {
                    RoundedRectangle(cornerRadius: 15)
                    // Set tabbar background
                        .toolbarBackground(.hidden, for: .tabBar)
                        .background {
                            Rectangle()
                                .frame(width: UIScreen.main.bounds.width + 100, height: 300)
                                .offset(y: 130)
                                .blur(radius: 25)
                                .foregroundStyle(.thinMaterial)
                        }
                        .foregroundStyle(.regularMaterial)
                    // add content
                        .overlay {
                            HStack {
                                ItemImage(cover: currentTrack.cover)
                                    .frame(width: 40, height: 40)
                                    .padding(.leading, 5)
                                
                                Text(currentTrack.name)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Group {
                                    Button {
                                        AudioPlayer.shared.setPlaying(!playing)
                                    } label: {
                                        Image(systemName: playing ?  "pause.fill" : "play.fill")
                                            .contentTransition(.symbolEffect(.replace))
                                    }
                                    
                                    Button {
                                        AudioPlayer.shared.advanceToNextTrack()
                                    } label: {
                                        Image(systemName: "forward.fill")
                                    }
                                    .padding(.horizontal, 10)
                                }
                                .imageScale(.large)
                            }
                            .padding(.horizontal, 6)
                        }
                    /*
                        .contextMenu(menuItems: {
                            Button {
                                AudioPlayer.shared.stopPlayback()
                            } label: {
                                Text("Stop playback")
                            }
                        })
                     */
                        .foregroundStyle(.primary)
                    // style bar
                        .padding(.horizontal, 15)
                        .padding(.bottom, 10)
                        .frame(height: 65)
                        .shadow(color: .black.opacity(0.25), radius: 20)
                        .onTapGesture {
                            nowPlayingSheetPresented.toggle()
                        }
                        .fullScreenCover(isPresented: $nowPlayingSheetPresented) {
                            NowPlayingSheet(track: currentTrack, playing: $playing)
                        }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.TrackChange), perform: { _ in
                withAnimation {
                    currentTrack = AudioPlayer.shared.nowPlaying
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.PlayPause), perform: { _ in
                withAnimation {
                    playing = AudioPlayer.shared.isPlaying()
                }
            })
    }
}

struct NowPlayingBarSafeAreaModifier: ViewModifier {
    @State var isVisible = AudioPlayer.shared.nowPlaying != nil
    
    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.bottom, isVisible ? 75 : 0)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.TrackChange), perform: { _ in
                withAnimation {
                    isVisible = AudioPlayer.shared.nowPlaying != nil
                }
            })
    }
}
