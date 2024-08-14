//
//  NowPlayingBar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    struct CompactBarModifier: ViewModifier {
        @Environment(ViewModel.self) private var viewModel
        @Environment(\.libraryDataProvider) private var dataProvider
        
        func body(content: Content) -> some View {
            content
                .safeAreaInset(edge: .bottom) {
                    if let nowPlaying = viewModel.nowPlaying {
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
                            
                            if !viewModel.presented {
                                Button {
                                    viewModel.setPresented(true)
                                } label: {
                                    HStack(spacing: 8) {
                                        ItemImage(cover: nowPlaying.cover)
                                            .frame(width: 40, height: 40)
                                            .matchedGeometryEffect(id: "image", in: viewModel.namespace, anchor: .topTrailing)
                                        
                                        Text(nowPlaying.name)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Group {
                                            Group {
                                                if viewModel.buffering {
                                                    ProgressView()
                                                } else {
                                                    Button {
                                                        AudioPlayer.current.playing.toggle()
                                                    } label: {
                                                        Label("playback.toggle", systemImage: viewModel.playing ?  "pause.fill" : "play.fill")
                                                            .labelStyle(.iconOnly)
                                                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                                            .animation(.spring(duration: 0.2, bounce: 0.7), value: viewModel.playing)
                                                    }
                                                }
                                            }
                                            .transition(.blurReplace)
                                            
                                            Button {
                                                AudioPlayer.current.advance()
                                            } label: {
                                                Label("playback.next", systemImage: "forward.fill")
                                                    .labelStyle(.iconOnly)
                                                    .symbolEffect(.bounce.up, value: viewModel.notifyForwards)
                                            }
                                            .padding(.horizontal, 8)
                                        }
                                        .imageScale(.large)
                                    }
                                }
                                .frame(height: 56)
                                .padding(.horizontal, 8)
                                .contentShape(.hoverMenuInteraction, .rect(cornerRadius: 16, style: .continuous))
                                .modifier(NowPlaying.ContextMenuModifier(track: nowPlaying))
                                .foregroundStyle(.primary)
                                .background(.regularMaterial)
                                .transition(.move(edge: .bottom))
                                .animation(.smooth, value: viewModel.presented)
                                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                                .draggable(nowPlaying) {
                                    TrackCollection.TrackPreview(track: nowPlaying)
                                        .padding()
                                }
                                .shadow(color: .black.opacity(0.4), radius: 20)
                                .padding(.bottom, 12)
                                .padding(.horizontal, 12)
                                .zIndex(1)
                                .dropDestination(for: Track.self) { tracks, _ in
                                    AudioPlayer.current.queue(tracks, after: 0, playbackInfo: .init(container: nil, queueLocation: .next))
                                    return true
                                }
                            }
                        }
                    }
                }
                .sensoryFeedback(.increase, trigger: viewModel.notifyForwards)
                .sensoryFeedback(AudioPlayer.current.playing ? .start : .stop, trigger: viewModel.notifyPlaying)
                .sensoryFeedback(.decrease, trigger: viewModel.notifyBackwards)
        }
    }
}
