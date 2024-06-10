//
//  NowPlayingBar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

extension NowPlaying {
    struct CompactBarModifier: ViewModifier {
        @Environment(CompactViewState.self) private var nowPlayingViewState
        @Environment(\.libraryDataProvider) private var dataProvider
        
        @State private var animateForwards = false
        
        func body(content: Content) -> some View {
            content
                .safeAreaInset(edge: .bottom) {
                    if let nowPlaying = AudioPlayer.current.nowPlaying {
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
                                .foregroundStyle(.bar)
                                .padding(.bottom, -225)
                                .allowsHitTesting(false)
                                .toolbarBackground(.hidden, for: .tabBar)
                            
                            if !nowPlayingViewState.presented {
                                HStack(spacing: 8) {
                                    ItemImage(cover: nowPlaying.cover)
                                        .frame(width: 40, height: 40)
                                        .matchedGeometryEffect(id: "image", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottomLeading, isSource: !nowPlayingViewState.presented)
                                    
                                    VStack(alignment: .leading, spacing: 0) {
                                        if AudioPlayer.current.outputRoute.showLabel {
                                            Text(AudioPlayer.current.outputRoute.name)
                                                .font(.subheadline.smallCaps())
                                                .fontDesign(.rounded)
                                                .lineLimit(1)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Text(nowPlaying.name)
                                            .lineLimit(1)
                                            .matchedGeometryEffect(id: "title", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottom, isSource: !nowPlayingViewState.presented)
                                    }
                                    
                                    Spacer()
                                    
                                    Group {
                                        Group {
                                            if AudioPlayer.current.buffering {
                                                ProgressView()
                                            } else {
                                                Button {
                                                    AudioPlayer.current.playing.toggle()
                                                } label: {
                                                    Label("playback.toggle", systemImage: AudioPlayer.current.playing ?  "pause.fill" : "play.fill")
                                                        .labelStyle(.iconOnly)
                                                        .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                                        .animation(.spring(duration: 0.2, bounce: 0.7), value: AudioPlayer.current.playing)
                                                }
                                                .sensoryFeedback(.selection, trigger: AudioPlayer.current.playing)
                                            }
                                        }
                                        .transition(.blurReplace)
                                        
                                        Button {
                                            animateForwards.toggle()
                                            AudioPlayer.current.advanceToNextTrack()
                                        } label: {
                                            Label("playback.next", systemImage: "forward.fill")
                                                .labelStyle(.iconOnly)
                                                .symbolEffect(.bounce.up, value: animateForwards)
                                        }
                                        .padding(.horizontal, 8)
                                        .sensoryFeedback(.increase, trigger: animateForwards)
                                    }
                                    .imageScale(.large)
                                }
                                .frame(height: 56)
                                .padding(.horizontal, 8)
                                .contentShape(.hoverMenuInteraction, .rect(cornerRadius: 16, style: .continuous))
                                .modifier(NowPlaying.ContextMenuModifier(track: nowPlaying, animateForwards: $animateForwards))
                                .foregroundStyle(.primary)
                                .background(.regularMaterial)
                                .transition(.move(edge: .bottom))
                                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                                .draggable(nowPlaying) {
                                    TrackListRow.TrackPreview(track: nowPlaying)
                                        .padding()
                                }
                                .shadow(color: .black.opacity(0.4), radius: 20)
                                .padding(.bottom, 12)
                                .padding(.horizontal, 12)
                                .zIndex(1)
                                .onTapGesture {
                                    nowPlayingViewState.setNowPlayingViewPresented(true)
                                }
                                .dropDestination(for: Track.self) { tracks, _ in
                                    AudioPlayer.current.queueTracks(tracks, index: 0, playbackInfo: .init(container: nil, queueLocation: .next))
                                    return true
                                }
                            }
                        }
                    }
                }
        }
    }
}
