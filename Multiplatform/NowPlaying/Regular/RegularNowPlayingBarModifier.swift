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
    
    @State private var animateImage = false
    @State private var animateRepeat = false
    @State private var animateShuffle = false
    @State private var animateForwards = false
    @State private var animateBackwards = false
    
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
                        
                        ZStack {
                            HStack {
                                ItemImage(cover: currentTrack.cover)
                                    .frame(width: 50, height: 50)
                                
                                Text(currentTrack.name)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Group {
                                    Button {
                                        animateShuffle.toggle()
                                        AudioPlayer.current.shuffled = !AudioPlayer.current.shuffled
                                    } label: {
                                        Image(systemName: "shuffle")
                                            .font(.footnote)
                                            .fontWeight(.heavy)
                                            .symbolEffect(.bounce.up, value: animateShuffle)
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
                                        animateRepeat.toggle()
                                        
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
                                        .symbolEffect(.bounce.up, value: animateRepeat)
                                    }
                                    .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none, heavy: true))
                                }
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 66)
                            .foregroundStyle(.primary)
                            .background {
                                Rectangle()
                                    .foregroundStyle(.ultraThinMaterial)
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
                            .zIndex(1)
                        }
                        .padding(.horizontal, 25)
                    }
                    // some dipshit at apple decided that the navigationstack inside the detail view of a navigationsplitview is purly cosmetic and doesnt do shit
                    // so this has to be added to the splitview itself, and we have to account for the sidebar width
                    // if i could be bothered i would open a bug report, but this would be the second time today and i am pretty sure that nobody looks at them,
                    // or at least that is the impression that the feedback assistent gives you.
                    // some other people have asked about this behaviour on the apple forums and stackoverflow but nobody cared
                    // https://forums.developer.apple.com/forums/thread/735672
                    // https://stackoverflow.com/questions/76167468/strange-navigation-with-navigationstack-inside-navigationsplitview
                    .padding(.leading, 320)
                    .dropDestination(for: Track.self) { tracks, _ in
                        AudioPlayer.current.queueTracks(tracks, index: 0)
                        return true
                    }
                }
            }
    }
}
