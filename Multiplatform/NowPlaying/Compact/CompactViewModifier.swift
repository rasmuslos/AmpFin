//
//  NowPlayingView.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

extension NowPlaying {
    struct CompactViewModifier: ViewModifier {
        @Namespace private var namespace
        
        @State private var viewModel = ViewModel()
        
        func body(content: Content) -> some View {
            ZStack {
                content
                    .allowsHitTesting(!viewModel.presented)
                
                if viewModel.track != nil {
                    Background()
                        .zIndex(1)
                        .offset(y: viewModel.dragOffset)
                        .transition(.asymmetric(
                            insertion: .modifier(active: BackgroundInsertTransitionModifier(active: true), identity: BackgroundInsertTransitionModifier(active: false)),
                            removal: .modifier(active: BackgroundRemoveTransitionModifier(active: true), identity: BackgroundRemoveTransitionModifier(active: false)))
                        )
                }
                
                VStack(spacing: 0) {
                    if let track = viewModel.track {
                        if viewModel.currentTab == .cover {
                            LargeTitle(track: track)
                                .modifier(GestureModifier(active: viewModel.currentTab == .cover))
                        } else {
                            SmallTitle(track: track)
                                .modifier(GestureModifier(active: true))
                                .padding(.top, 40)
                            
                            Group {
                                if viewModel.currentTab == .lyrics {
                                    Lyrics(track: track)
                                } else if viewModel.currentTab == .queue {
                                    Queue()
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom),
                                removal: .move(edge: .bottom).combined(with: .opacity)))
                        }
                        
                        if viewModel.controlsVisible {
                            VStack(spacing: 0) {
                                Controls(compact: false)
                                    .modifier(GestureModifier(active: viewModel.currentTab == .cover))
                                
                                Buttons()
                                    .padding(.top, 28)
                                    .padding(.horizontal, -28)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 28)
                            .transition(.modifier(active: CollapseTransitionModifier(active: true), identity: CollapseTransitionModifier(active: false)))
                            .animation(.timingCurve(0.13, 1.21, 0.46, 0.79, duration: 0.5), value: viewModel.controlsVisible)
                            .transaction {
                                guard $0.nowPlayingOverlayToggled else {
                                    return
                                }
                                
                                if viewModel.track == nil {
                                    $0.animation = .smooth
                                } else {
                                    $0.animation = .smooth.delay(0.1)
                                }
                            }
                        }
                    }
                }
                .zIndex(2)
                .foregroundStyle(.white)
                .overlay(alignment: .top) {
                    if viewModel.track != nil {
                        Button {
                            viewModel.setNowPlayingViewPresented(false)
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
                        .transaction {
                            guard $0.nowPlayingOverlayToggled else {
                                return
                            }
                            
                            if viewModel.track == nil {
                                $0.animation = .smooth
                            } else {
                                $0.animation = .smooth.delay(0.3)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.safeAreaInsets.top)
                .offset(y: viewModel.dragOffset)
                .environment(\.colorScheme, .light)
                .allowsHitTesting(viewModel.track != nil)
                .persistentSystemOverlays(AudioPlayer.current.outputRoute.showLabel ? .hidden : .automatic)
            }
            .ignoresSafeArea(edges: .all)
            .environment(viewModel)
            .modifier(Navigation.NavigationModifier() {
                viewModel.setNowPlayingViewPresented(false)
            })
            .onAppear {
                viewModel.namespace = namespace
            }
            .onChange(of: AudioPlayer.current.nowPlaying) { previous, current in
                if previous == nil {
                    viewModel.setNowPlayingViewPresented(true)
                }
                
                if current == nil {
                    viewModel.setNowPlayingViewPresented(false)
                }
            }
            .task(id: AudioPlayer.current.nowPlaying) {
                await viewModel.trackDidChange()
            }
            .sheet(item: .init(get: { viewModel.addToPlaylistTrack }, set: { viewModel.addToPlaylistSheetPresented = ($0 != nil) })) {
                PlaylistAddSheet(track: $0)
            }
        }
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
                        
                        if $0.velocity.height > 3000 {
                            viewModel.setNowPlayingViewPresented(false)
                        } else if $0.velocity.height < -3000 {
                            viewModel.dragOffset = 0
                        } else {
                            viewModel.dragOffset = max(0, $0.translation.height)
                        }
                    }
                    .onEnded {
                        if $0.translation.height > 200 && viewModel.dragOffset != 0 {
                            viewModel.setNowPlayingViewPresented(false)
                        } else {
                            viewModel.dragOffset = 0
                        }
                    }
            )
    }
}

private struct BackgroundInsertTransitionModifier: ViewModifier {
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .mask(alignment: .bottom) {
                Rectangle()
                    .frame(maxHeight: active ? 0 : .infinity)
                    .padding(.horizontal, active ? 12 : 0)
                    .offset(y: active ? -146 : 0)
                    .animation(.timingCurve(0.9, 0, 0.9, 1.6, duration: 0.5), value: active)
            }
            .opacity(active ? 0 : 1)
            .animation(.smooth(duration: 0.1), value: active)
    }
}

// This is more a "collapse" than a move thing
private struct BackgroundRemoveTransitionModifier: ViewModifier {
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .mask(alignment: .bottom) {
                Rectangle()
                    .frame(maxHeight: active ? 0 : .infinity)
                    .padding(.horizontal, active ? 12 : 0)
                    .offset(y: active ? -92 : 0)
            }
            .opacity(active ? 0.5 : 1)
            .animation(.timingCurve(-0.1, 0, 0.8, 1, duration: 0.3), value: active)
    }
}

private struct CollapseTransitionModifier: ViewModifier {
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .frame(height: active ? 0 : nil)
            .clipped()
    }
}
