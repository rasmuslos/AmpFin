//
//  NowPlayingBar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AFBase
import AFPlayback

// For some fucking reason animations do not work on `NavigationStack`, so this has to be added to every view... WHY?

struct NowPlayingBarModifier: ViewModifier {
    @Environment(NowPlayingViewState.self) private var nowPlayingViewState
    @Environment(\.libraryDataProvider) private var dataProvider
    
    @State private var animateImage = false
    @State private var animateForwards = false
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let currentTrack = AudioPlayer.current.nowPlaying {
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .frame(height: 300)
                            .mask {
                                VStack(spacing: 0) {
                                    LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                                        .frame(height: 50)
                                    
                                    Rectangle()
                                        .frame(height: 250)
                                }
                            }
                            .foregroundStyle(.regularMaterial)
                            .padding(.bottom, -225)
                        
                        if !nowPlayingViewState.presented {
                            Group {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .foregroundStyle(.thinMaterial)
                                    .transition(.move(edge: .top))
                                    .frame(width: UIScreen.main.bounds.width - 16, height: 56)
                                    .zIndex(2)
                                
                                HStack {
                                    ItemImage(cover: currentTrack.cover)
                                        .frame(width: 40, height: 40)
                                        .padding(.leading, 5)
                                        .matchedGeometryEffect(id: "image", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottomLeading, isSource: !nowPlayingViewState.presented)
                                    
                                    Text(currentTrack.name)
                                        .lineLimit(1)
                                        .matchedGeometryEffect(id: "title", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottom, isSource: !nowPlayingViewState.presented)
                                    
                                    Spacer()
                                    
                                    Group {
                                        Button {
                                            AudioPlayer.current.playing = !AudioPlayer.current.playing
                                        } label: {
                                            Image(systemName: AudioPlayer.current.playing ?  "pause.fill" : "play.fill")
                                                .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                                .scaleEffect(animateImage ? AudioPlayer.current.playing ? 1.1 : 0.9 : 1)
                                                .animation(.spring(duration: 0.2, bounce: 0.7), value: animateImage)
                                                .onChange(of: AudioPlayer.current.playing) {
                                                    withAnimation {
                                                        animateImage = true
                                                    } completion: {
                                                        animateImage = false
                                                    }
                                                }
                                        }
                                        
                                        Button {
                                            animateForwards.toggle()
                                            AudioPlayer.current.advanceToNextTrack()
                                        } label: {
                                            Image(systemName: "forward.fill")
                                                .symbolEffect(.bounce.up, value: animateForwards)
                                        }
                                        .padding(.horizontal, 10)
                                    }
                                    .imageScale(.large)
                                }
                                .padding(.horizontal, 6)
                                .zIndex(3)
                                .frame(width: UIScreen.main.bounds.width - 10, height: 56)
                                .modifier(ContextMenuModifier(track: currentTrack, animateForwards: $animateForwards))
                            }
                            .toolbarBackground(.hidden, for: .tabBar)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .foregroundStyle(.primary)
                            .shadow(color: .black.opacity(0.25), radius: 20)
                            .draggable(currentTrack) {
                                TrackListRow.TrackPreview(track: currentTrack)
                                    .padding()
                            }
                            .padding(.bottom, 10)
                            .onTapGesture {
                                nowPlayingViewState.setNowPlayingViewPresented(true)
                            }
                        }
                    }
                }
            }
            .dropDestination(for: Track.self) { tracks, _ in
                AudioPlayer.current.queueTracks(tracks, index: 0)
                return true
            }
    }
}

struct NowPlayingBarSafeAreaModifier: ViewModifier {
    private var isVisible: Bool {
        AudioPlayer.current.nowPlaying != nil
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.bottom, isVisible ? 75 : 0)
    }
}
