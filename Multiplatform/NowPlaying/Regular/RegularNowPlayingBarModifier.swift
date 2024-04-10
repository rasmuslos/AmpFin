//
//  CompactNowPlayingBarModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AFBase
import AFPlayback

struct RegularNowPlayingBarModifier: ViewModifier {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    @State private var width: CGFloat = .zero
    @State private var adjust: CGFloat = .zero
    @State private var sheetPresented = false
    
    @State private var animateImage = false
    @State private var animateForwards = false
    @State private var animateBackwards = false
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let currentTrack = AudioPlayer.current.nowPlaying {
                    VStack {
                        HStack {
                            ItemImage(cover: currentTrack.cover)
                                .frame(width: 50, height: 50)
                            
                            Text(currentTrack.name)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Group {
                                Button {
                                    AudioPlayer.current.shuffled = !AudioPlayer.current.shuffled
                                } label: {
                                    Image(systemName: "shuffle")
                                        .font(.footnote)
                                        .fontWeight(.heavy)
                                }
                                .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.shuffled, heavy: true))
                                
                                Button {
                                    animateBackwards.toggle()
                                    AudioPlayer.current.backToPreviousItem()
                                } label: {
                                    Image(systemName: "backward.fill")
                                        .symbolEffect(.bounce.up, value: animateBackwards)
                                }
                                .font(.title3)
                                .padding(.horizontal, 7)
                                
                                Group {
                                    if AudioPlayer.current.buffering {
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
                                .frame(width: 30)
                                .transition(.blurReplace)
                                .font(.title)
                                
                                Button {
                                    animateForwards.toggle()
                                    AudioPlayer.current.advanceToNextTrack()
                                } label: {
                                    Image(systemName: "forward.fill")
                                        .symbolEffect(.bounce.up, value: animateForwards)
                                }
                                .font(.title3)
                                .padding(.horizontal, 7)
                                
                                Button {
                                    if AudioPlayer.current.repeatMode == .none {
                                        AudioPlayer.current.repeatMode = .queue
                                    } else if AudioPlayer.current.repeatMode == .queue {
                                        AudioPlayer.current.repeatMode = .track
                                    } else if AudioPlayer.current.repeatMode == .track {
                                        AudioPlayer.current.repeatMode = .none
                                    }
                                } label: {
                                    Group {
                                        if AudioPlayer.current.repeatMode == .track {
                                            Image(systemName: "repeat.1")
                                        } else if AudioPlayer.current.repeatMode == .none || AudioPlayer.current.repeatMode == .queue {
                                            Image(systemName: "repeat")
                                        }
                                    }
                                    .font(.footnote)
                                    .fontWeight(.heavy)
                                }
                                .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none, heavy: true))
                            }
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 66)
                        .frame(maxWidth: width)
                        .foregroundStyle(.primary)
                        .background {
                            Rectangle()
                                .foregroundStyle(.regularMaterial)
                        }
                        .transition(.move(edge: .bottom))
                        .modifier(NowPlayingBarContextMenuModifier(track: currentTrack, animateForwards: $animateForwards))
                        .draggable(currentTrack) {
                            TrackListRow.TrackPreview(track: currentTrack)
                                .padding()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 20)
                        .padding(.bottom, 10)
                        .dropDestination(for: Track.self) { tracks, _ in
                            AudioPlayer.current.queueTracks(tracks, index: 0)
                            return true
                        }
                        .onTapGesture {
                            sheetPresented.toggle()
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.leading, adjust)
                    .animation(.spring, value: width)
                    .animation(.spring, value: adjust)
                    .fullScreenCover(isPresented: $sheetPresented) {
                        RegularNowPlayingView()
                            .ignoresSafeArea(edges: .all)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("a"))) { notification in
                if let width = notification.object as? CGFloat {
                    self.width = min(width, 1100)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("b"))) { notification in
                if let offset = notification.object as? CGFloat {
                    adjust = offset
                }
            }
    }
}
