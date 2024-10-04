//
//  CompactNowPlayingBarModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    struct RegularBarModifier: ViewModifier {
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        @Environment(\.libraryDataProvider) private var dataProvider
        
        @State private var width: CGFloat = .zero
        @State private var adjust: CGFloat = .zero
        
        func body(content: Content) -> some View {
            @Bindable var viewModel = viewModel
            
            content
                .safeAreaInset(edge: .bottom) {
                    if let currentTrack = viewModel.nowPlaying {
                        HStack(spacing: 8) {
                            ItemImage(cover: currentTrack.cover)
                                .frame(width: 48, height: 48)
                            
                            Text(currentTrack.name)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button {
                                AudioPlayer.current.shuffled.toggle()
                            } label: {
                                Label("shuffle", systemImage: "shuffle")
                                    .labelStyle(.iconOnly)
                                    .font(.footnote)
                                    .fontWeight(.heavy)
                            }
                            .buttonStyle(SymbolButtonStyle(active: viewModel.shuffled, heavy: true))
                            .modifier(HoverEffectModifier(padding: 4))
                            
                            Button {
                                AudioPlayer.current.rewind()
                            } label: {
                                Label("playback.back", systemImage: "backward.fill")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce.up, value: viewModel.notifyBackwards)
                            }
                            .font(.title3)
                            .modifier(HoverEffectModifier())
                            
                            Group {
                                if viewModel.buffering {
                                    ProgressView()
                                } else {
                                    Button {
                                        AudioPlayer.current.playing.toggle()
                                    } label: {
                                        Label("playback.toggle", systemImage: viewModel.playing ? "pause.fill" : "play.fill")
                                            .labelStyle(.iconOnly)
                                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                    }
                                }
                            }
                            .frame(width: 32)
                            .font(.title)
                            .modifier(HoverEffectModifier())
                            .transition(.blurReplace)
                            
                            Button {
                                AudioPlayer.current.advance()
                            } label: {
                                Label("playback.next", systemImage: "forward.fill")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce.up, value: viewModel.notifyForwards)
                            }
                            .font(.title3)
                            .modifier(HoverEffectModifier())
                            
                            Button {
                                AudioPlayer.current.repeatMode = viewModel.repeatMode.next
                            } label: {
                                Label("repeat", systemImage: viewModel.repeatMode == .infinite ? "infinity" : "repeat\(viewModel.repeatMode == .track ? ".1" : "")")
                                    .labelStyle(.iconOnly)
                                    .font(.footnote)
                                    .fontWeight(.heavy)
                            }
                            .buttonStyle(SymbolButtonStyle(active: viewModel.repeatMode != .none, heavy: true))
                            .modifier(HoverEffectModifier(padding: 4))
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 66)
                        .frame(maxWidth: width)
                        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .foregroundStyle(.primary)
                        .background {
                            Rectangle()
                                .foregroundStyle(.bar)
                        }
                        .modifier(NowPlaying.ContextMenuModifier(track: currentTrack))
                        .draggable(currentTrack) {
                            TrackCollection.TrackPreview(track: currentTrack)
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
                            viewModel.expanded = true
                        }
                        .dropDestination(for: Track.self) { tracks, _ in
                            AudioPlayer.current.queue(tracks, after: 0, playbackInfo: .init(container: nil, queueLocation: .next))
                            return true
                        }
                        .fullScreenCover(isPresented: $viewModel.expanded) {
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
                .environment(viewModel)
        }
    }
}
