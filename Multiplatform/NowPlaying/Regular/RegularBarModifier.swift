//
//  CompactNowPlayingBarModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback

extension NowPlaying {
    struct RegularBarModifier: ViewModifier {
        @Environment(\.libraryDataProvider) private var dataProvider
        
        @State private var width: CGFloat = .zero
        @State private var adjust: CGFloat = .zero
        @State private var sheetPresented = false
        
        @State private var animateForwards = false
        @State private var animateBackwards = false
        
        func body(content: Content) -> some View {
            content
                .safeAreaInset(edge: .bottom) {
                    if let currentTrack = AudioPlayer.current.nowPlaying {
                        HStack(spacing: 8) {
                            ItemImage(cover: currentTrack.cover)
                                .frame(width: 48, height: 48)
                            
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
                            .modifier(HoverEffectModifier(padding: 4))
                            
                            Button {
                                animateBackwards.toggle()
                                AudioPlayer.current.backToPreviousItem()
                            } label: {
                                Label("playback.back", systemImage: "backward.fill")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce.up, value: animateBackwards)
                            }
                            .font(.title3)
                            .modifier(HoverEffectModifier())
                            .sensoryFeedback(.decrease, trigger: animateBackwards)
                            
                            Group {
                                if AudioPlayer.current.buffering {
                                    ProgressView()
                                } else {
                                    Button {
                                        AudioPlayer.current.playing.toggle()
                                    } label: {
                                        Label("playback.toggle", systemImage: AudioPlayer.current.playing ? "pause.fill" : "play.fill")
                                            .labelStyle(.iconOnly)
                                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                    }
                                }
                            }
                            .frame(width: 32)
                            .font(.title)
                            .modifier(HoverEffectModifier())
                            .transition(.blurReplace)
                            .sensoryFeedback(.selection, trigger: AudioPlayer.current.playing)
                            
                            Button {
                                animateForwards.toggle()
                                AudioPlayer.current.advanceToNextTrack()
                            } label: {
                                Label("playback.next", systemImage: "forward.fill")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce.up, value: animateForwards)
                            }
                            .font(.title3)
                            .modifier(HoverEffectModifier())
                            .sensoryFeedback(.increase, trigger: animateForwards)
                            
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
                            .modifier(HoverEffectModifier(padding: 4))
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 66)
                        .frame(maxWidth: width)
                        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .foregroundStyle(.primary)
                        .background {
                            Rectangle()
                                .foregroundStyle(.regularMaterial)
                        }
                        .modifier(NowPlaying.ContextMenuModifier(track: currentTrack, animateForwards: $animateForwards))
                        .draggable(currentTrack) {
                            TrackListRow.TrackPreview(track: currentTrack)
                                .padding()
                        }
                        .clipShape(.rect(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 20)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 10)
                        .padding(.leading, adjust)
                        .animation(.spring, value: width)
                        .animation(.spring, value: adjust)
                        .onTapGesture {
                            sheetPresented.toggle()
                        }
                        .dropDestination(for: Track.self) { tracks, _ in
                            AudioPlayer.current.queueTracks(tracks, index: 0, playbackInfo: .init(container: nil, queueLocation: .next))
                            return true
                        }
                        .fullScreenCover(isPresented: $sheetPresented) {
                            RegularView()
                                .ignoresSafeArea(edges: .all)
                        }
                    }
                }
                .onChange(of: AudioPlayer.current.nowPlaying) { previous, current in
                    guard previous == nil && current != nil else {
                        return
                    }
                    
                    sheetPresented = true
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
