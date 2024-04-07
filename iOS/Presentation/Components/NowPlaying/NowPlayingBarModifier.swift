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
                            .allowsHitTesting(false)
                            .toolbarBackground(.hidden, for: .tabBar)
                            .ignoresSafeArea(edges: .all)
                        
                        if !nowPlayingViewState.presented {
                            ViewThatFits(in: .horizontal) {
                                // Full control when space permits
                                HStack {
                                    ItemImage(cover: currentTrack.cover)
                                        .frame(width: 40, height: 40)
                                        .matchedGeometryEffect(id: "image", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottomLeading, isSource: !nowPlayingViewState.presented)
                                    
                                    Text(currentTrack.name)
                                        .lineLimit(1)
                                        .matchedGeometryEffect(id: "title", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottom, isSource: !nowPlayingViewState.presented)
                                    
                                    Spacer()
                                    
                                    Group {
                                        Button {
                                            AudioPlayer.current.shuffled = !AudioPlayer.current.shuffled
                                        } label: {
                                            Image(systemName: "shuffle")
                                                .font(Font.footnote.weight(.heavy))
                                        }
                                        .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.shuffled, heavy: true))
                                        .padding(.horizontal, 10)
                                        Button {
                                            AudioPlayer.current.backToPreviousItem()
                                        } label: {
                                            Image(systemName: "backward.fill")
                                        }
                                        .padding(.horizontal, 10)
                                        Group {
                                            // A paused track will very likely to have an empty buffer
                                            // For example, forwarding or backwarding during pausing
                                            if AudioPlayer.current.playing, AudioPlayer.current.buffering {
                                                ProgressView()
                                            } else {
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
                                            }
                                        }
                                        .transition(.blurReplace)
                                        
                                        Button {
                                            animateForwards.toggle()
                                            AudioPlayer.current.advanceToNextTrack()
                                        } label: {
                                            Image(systemName: "forward.fill")
                                                .symbolEffect(.bounce.up, value: animateForwards)
                                        }
                                        .padding(.horizontal, 10)
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
                                                    .font(Font.footnote.weight(.heavy))
                                            } else if AudioPlayer.current.repeatMode == .none || AudioPlayer.current.repeatMode == .queue {
                                                Image(systemName: "repeat")
                                                    .font(Font.footnote.weight(.heavy))
                                            }
                                        }
                                        .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none, heavy: true))
                                        .padding(.horizontal, 10)
                                    }
                                    .imageScale(.large)
                                }
                                // Simplified control when space is limited
                                HStack {
                                    ItemImage(cover: currentTrack.cover)
                                        .frame(width: 40, height: 40)
                                        .matchedGeometryEffect(id: "image", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottomLeading, isSource: !nowPlayingViewState.presented)
                                    
                                    Text(currentTrack.name)
                                        .lineLimit(1)
                                        .matchedGeometryEffect(id: "title", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottom, isSource: !nowPlayingViewState.presented)
                                    
                                    Spacer()
                                    
                                    Group {
                                        Group {
                                            if AudioPlayer.current.playing, AudioPlayer.current.buffering {
                                                ProgressView()
                                            } else {
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
                                            }
                                        }
                                        .transition(.blurReplace)
                                        
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
                            }
                            .frame(maxWidth: 800, maxHeight: 56)
                            .padding(.horizontal, 8)
                            .foregroundStyle(.primary)
                            .background {
                                Rectangle()
                                    .foregroundStyle(.ultraThinMaterial)
                            }
                            .transition(.move(edge: .bottom))
                            .modifier(ContextMenuModifier(track: currentTrack, animateForwards: $animateForwards))
                            .draggable(currentTrack) {
                                TrackListRow.TrackPreview(track: currentTrack)
                                    .padding()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .shadow(color: .black.opacity(0.25), radius: 20)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 32)
                            .zIndex(1)
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
