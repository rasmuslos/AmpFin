//
//  CompactNowPlayingBarModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AFBase
import AFPlayback

extension NowPlaying {
    struct RegularBarModifier: ViewModifier {
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
                        HStack {
                            ItemImage(cover: currentTrack.cover)
                                .frame(width: 50, height: 50)
                            
                            Text(currentTrack.name)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button {
                                AudioPlayer.current.shuffled = !AudioPlayer.current.shuffled
                            } label: {
                                Label("shuffle", systemImage: "shuffle")
                                    .labelStyle(.iconOnly)
                                    .font(.footnote)
                                    .fontWeight(.heavy)
                            }
                            .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.shuffled, heavy: true))
                            .modifier(ButtonHoverEffectModifier())
                            
                            Button {
                                animateBackwards.toggle()
                                AudioPlayer.current.backToPreviousItem()
                            } label: {
                                Label("playback.back", systemImage: "backward.fill")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce.up, value: animateBackwards)
                            }
                            .font(.title3)
                            .modifier(ButtonHoverEffectModifier())
                            .padding(.horizontal, 7)
                            
                            Group {
                                if AudioPlayer.current.buffering {
                                    ProgressView()
                                } else {
                                    Button {
                                        AudioPlayer.current.playing = !AudioPlayer.current.playing
                                    } label: {
                                        Label("playback.toggle", systemImage: AudioPlayer.current.playing ? "pause.fill" : "play.fill")
                                            .labelStyle(.iconOnly)
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
                            .modifier(ButtonHoverEffectModifier())
                            .font(.title)
                            
                            Button {
                                animateForwards.toggle()
                                AudioPlayer.current.advanceToNextTrack()
                            } label: {
                                Label("playback.next", systemImage: "forward.fill")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce.up, value: animateForwards)
                            }
                            .font(.title3)
                            .modifier(ButtonHoverEffectModifier())
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
                                Label("repeat", systemImage: "repeat\(AudioPlayer.current.repeatMode == .track ? ".1" : "")")
                                    .labelStyle(.iconOnly)
                                    .font(.footnote)
                                    .fontWeight(.heavy)
                            }
                            .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none, heavy: true))
                            .modifier(ButtonHoverEffectModifier())
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 66)
                        .frame(maxWidth: width)
                        .foregroundStyle(.primary)
                        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .modifier(NowPlaying.ContextMenuModifier(track: currentTrack, animateForwards: $animateForwards))
                        .background {
                            Rectangle()
                                .foregroundStyle(.regularMaterial)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .hoverEffect(.highlight)
                        .draggable(currentTrack) {
                            TrackListRow.TrackPreview(track: currentTrack)
                                .padding()
                        }
                        .shadow(color: .black.opacity(0.25), radius: 20)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 25)
                        .padding(.leading, adjust)
                        .animation(.spring, value: width)
                        .animation(.spring, value: adjust)
                        .dropDestination(for: Track.self) { tracks, _ in
                            AudioPlayer.current.queueTracks(tracks, index: 0, playbackInfo: .init(container: nil, queueLocation: .next))
                            return true
                        }
                        .onTapGesture {
                            sheetPresented.toggle()
                        }
                        .fullScreenCover(isPresented: $sheetPresented) {
                            RegularView()
                                .ignoresSafeArea(edges: .all)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NowPlaying.widthChangeNotification)) { notification in
                    if let width = notification.object as? CGFloat {
                        self.width = min(width, 1100)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NowPlaying.offsetChangeNotification)) { notification in
                    if let offset = notification.object as? CGFloat {
                        adjust = offset
                    }
                }
        }
    }
}
