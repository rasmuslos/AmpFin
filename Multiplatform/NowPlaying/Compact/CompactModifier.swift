//
//  NowPlayingView.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    struct CompactModifier: ViewModifier {
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        func body(content: Content) -> some View {
            @Bindable var viewModel = viewModel
            
            ZStack(alignment: .bottom) {
                content
                    .allowsHitTesting(!viewModel.expanded)
                
                if let track = viewModel.nowPlaying {
                    ZStack {
                        // Background
                        ZStack {
                            // Prevent content from shining through
                            if viewModel.expanded {
                                Rectangle()
                                    .foregroundStyle(.background)
                                    .transition(.opacity)
                                    .transaction {
                                        if !viewModel.expanded {
                                            $0.animation = .smooth.delay(0.6)
                                        }
                                    }
                            }
                            
                            // Now playing bar background
                            Rectangle()
                                .foregroundStyle(.regularMaterial)
                                .opacity(viewModel.expanded ? 0 : 1)
                            
                            // Now playing view background
                            Background()
                                .opacity(viewModel.expanded ? 1 : 0)
                        }
                        .allowsHitTesting(false)
                        .mask {
                            VStack(spacing: 0) {
                                UnevenRoundedRectangle(topLeadingRadius: viewModel.backgroundCornerRadius, topTrailingRadius: viewModel.backgroundCornerRadius, style: .continuous)
                                    .frame(maxHeight: 60)
                                
                                // The padding prevents the mask from cutting lines in the background
                                // during the transformation. They are caused by the `spring` animation.
                                Rectangle()
                                    .padding(.vertical, -2)
                                
                                UnevenRoundedRectangle(bottomLeadingRadius: viewModel.backgroundCornerRadius, bottomTrailingRadius: viewModel.backgroundCornerRadius, style: .continuous)
                                    .frame(maxHeight: 60)
                            }
                            .drawingGroup()
                        }
                        .shadow(color: .black.opacity(0.4), radius: 20)
                        
                        // Drag gesture catcher
                        if viewModel.expanded {
                            Rectangle()
                                .foregroundStyle(.clear)
                                .contentShape(.rect)
                                .modifier(GestureModifier(active: true))
                        }
                        
                        // Foreground
                        VStack(spacing: 0) {
                            CollapsedForeground(track: track)
                                .opacity(viewModel.expanded ? 0 : 1)
                                .allowsHitTesting(!viewModel.expanded)
                            
                            ExpandedForeground(track: track)
                                .transition(.move(edge: .bottom))
                        }
                    }
                    .offset(x: 0, y: viewModel.dragOffset)
                    .ignoresSafeArea(.keyboard)
                    .ignoresSafeArea(edges: .all)
                    .toolbarBackground(.hidden, for: .tabBar)
                    .frame(height: viewModel.expanded ? nil : 56)
                    .padding(.horizontal, viewModel.expanded ? 0 : 12)
                    .padding(.bottom, viewModel.expanded ? 0 : 88)
                    .animation(.snappy(duration: 0.8), value: viewModel.expanded)
                }
                
            }
            .ignoresSafeArea(edges: .all)
            .sheet(item: $viewModel.addToPlaylistTrack) {
                PlaylistAddSheet(track: $0)
            }
            .modifier(Navigation.NavigationModifier() {
                viewModel.expanded = false
            })
        }
    }
}

private struct ExpandedForeground: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let track: Track
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.expanded && viewModel.currentTab == .cover {
                NowPlaying.LargeTitle(track: track)
                    .modifier(GestureModifier(active: true))
            }
            
            if viewModel.expanded {
                VStack(spacing: 0) {
                    if viewModel.currentTab != .cover {
                        NowPlaying.SmallTitle(track: track)
                            .modifier(GestureModifier(active: true))
                            .padding(.top, 40)
                        
                        if viewModel.currentTab == .lyrics {
                            NowPlaying.Lyrics()
                        } else if viewModel.currentTab == .queue {
                            NowPlaying.Queue()
                        }
                    }
                    
                    if viewModel.controlsVisible {
                        VStack(spacing: 0) {
                            NowPlaying.Controls(compact: false)
                                .padding(.top, 4)
                            
                            NowPlaying.Buttons()
                                .padding(.top, 28)
                                .padding(.horizontal, -28)
                        }
                        .padding(.top, viewModel.currentTab == .cover ? 20 : 0)
                        .padding(.bottom, 28)
                        .transition(.move(edge: .bottom))
                    }
                }
                .transition(.move(edge: .bottom))
            }
        }
        .foregroundStyle(.white)
        .overlay(alignment: .top) {
            if viewModel.expanded {
                Button {
                    viewModel.expanded = false
                } label: {
                    Rectangle()
                        .foregroundStyle(.thinMaterial)
                        .frame(width: 32, height: 4)
                        .clipShape(.rect(cornerRadius: .infinity))
                }
                .padding(40)
                .modifier(GestureModifier(active: true))
                .padding(-40)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 28)
        .environment(\.colorScheme, .light)
        .persistentSystemOverlays(viewModel.outputRoute.showLabel ? .hidden : .automatic)
    }
}
private struct CollapsedForeground: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let track: Track
    
    var body: some View {
        Button {
            viewModel.expanded.toggle()
        } label: {
            HStack(spacing: 8) {
                if !viewModel.expanded {
                    ItemImage(cover: track.cover, cornerRadius: 8)
                        .frame(width: 40, height: 40)
                        .matchedGeometryEffect(id: "image", in: viewModel.namespace, properties: .frame, anchor: .topLeading)
                } else {
                    Rectangle()
                        .hidden()
                        .frame(width: 40, height: 40)
                }
                
                Text(track.name)
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
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .frame(height: 56)
        .clipShape(.rect(cornerRadius: 12, style: .continuous))
        .contentShape(.hoverMenuInteraction, .rect(cornerRadius: 16, style: .continuous))
        .modifier(NowPlaying.ContextMenuModifier(track: track))
        .draggable(track) {
            TrackCollection.TrackPreview(track: track)
                .padding()
        }
        .dropDestination(for: Track.self) { tracks, _ in
            AudioPlayer.current.queue(tracks, after: 0, playbackInfo: .init(container: nil, queueLocation: .next))
            return true
        }
        .padding(.horizontal, 8)
    }
}

private struct GestureModifier: ViewModifier {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: active ? 0 : 1000, coordinateSpace: .global)
                    .onChanged {
                        guard !viewModel.controlsDragging else {
                            return
                        }
                        
                        if $0.velocity.height > 3500 {
                            viewModel.expanded = false
                        } else {
                            viewModel.dragOffset = min(1000, max(0, $0.translation.height))
                        }
                    }
                    .onEnded {
                        if $0.translation.height > 200 {
                            viewModel.expanded = false
                        } else {
                            withAnimation {
                                viewModel.dragOffset = 0
                            }
                        }
                    }
            )
    }
}
