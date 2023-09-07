//
//  NowPlayingBar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

struct NowPlayingBarModifier: ViewModifier {
    @State var playing = false
    @State var currentItem: SongItem?
    
    @State var nowPlayingSheetPresented = false
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let currentItem = currentItem {
                    RoundedRectangle(cornerRadius: 15)
                    // Set tabbar background
                        .toolbarBackground(.hidden, for: .tabBar)
                        .background {
                            Rectangle()
                                .frame(width: UIScreen.main.bounds.width + 100, height: 300)
                                .offset(y: 130)
                                .blur(radius: 25)
                                .foregroundStyle(.ultraThickMaterial)
                        }
                        .foregroundStyle(.ultraThinMaterial)
                    // add content
                        .overlay {
                            HStack {
                                ItemImage(cover: currentItem.cover)
                                    .frame(width: 40, height: 40)
                                    .padding(.leading, 5)
                                
                                Text(currentItem.name)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Group {
                                    Button {
                                        AudioPlayer.shared.setPlaying(!playing)
                                    } label: {
                                        if playing {
                                            Image(systemName: "pause.fill")
                                        } else {
                                            Image(systemName: "play.fill")
                                        }
                                    }
                                    
                                    Button {
                                        AudioPlayer.shared.playNextItem()
                                    } label: {
                                        Image(systemName: "forward.fill")
                                    }
                                    .padding(.horizontal, 10)
                                }
                                .imageScale(.large)
                            }
                            .padding(.horizontal, 6)
                        }
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
                            NowPlayingSheet(item: currentItem, playing: $playing)
                        }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.ItemChange), perform: { _ in
                withAnimation {
                    currentItem = AudioPlayer.shared.nowPlaying
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
    @State var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.bottom, isVisible ? 75 : 0)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.ItemChange), perform: { _ in
                withAnimation {
                    isVisible = AudioPlayer.shared.nowPlaying != nil
                }
            })
    }
}
