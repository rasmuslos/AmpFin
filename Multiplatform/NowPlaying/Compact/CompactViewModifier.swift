//
//  NowPlayingView.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import UIImageColors
import AmpFinKit
import AFPlayback

extension NowPlaying {
    struct CompactViewModifier: ViewModifier {
        @Namespace private var namespace
        
        @State private var viewState = CompactViewState.init()
        
        @State private var controlsVisible = true
        @State private var currentTab = Tab.cover
        
        @State private var controlsDragging = false
        @State private var dragOffset: CGFloat = .zero
        
        private var presentedTrack: Track? {
            if viewState.presented, let track = AudioPlayer.current.nowPlaying {
                return track
            }
            
            return nil
        }
        
        func body(content: Content) -> some View {
            ZStack {
                content
                    .allowsHitTesting(!viewState.presented)
                
                if let track = presentedTrack {
                    Background(cover: track.cover, dragging: viewState.dragOffset != 0)
                        .zIndex(1)
                        .offset(y: viewState.dragOffset)
                        .transition(.asymmetric(
                            insertion: .modifier(active: BackgroundInsertTransitionModifier(active: true), identity: BackgroundInsertTransitionModifier(active: false)),
                            removal: .modifier(active: BackgroundRemoveTransitionModifier(active: true), identity: BackgroundRemoveTransitionModifier(active: false)))
                        )
                }
                
                VStack(spacing: 0) {
                    if let track = presentedTrack {
                        if currentTab == .cover {
                            LargeTitle(track: track, currentTab: currentTab, namespace: namespace, presented: viewState.presented)
                                .modifier(GestureModifier(active: currentTab == .cover, controlsDragging: controlsDragging, dragOffset: $viewState.dragOffset))
                        } else {
                            SmallTitle(track: track, namespace: namespace, currentTab: $currentTab)
                                .modifier(GestureModifier(active: true, controlsDragging: controlsDragging, dragOffset: $viewState.dragOffset))
                                .padding(.top, 40)
                            
                            Group {
                                if currentTab == .lyrics {
                                    Lyrics(controlsVisible: $controlsVisible)
                                } else if currentTab == .queue {
                                    Queue()
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom),
                                removal: .move(edge: .bottom).combined(with: .opacity)))
                        }
                        
                        if controlsVisible {
                            VStack(spacing: 0) {
                                Controls(compact: false, controlsDragging: $controlsDragging)
                                    .modifier(GestureModifier(active: currentTab == .cover, controlsDragging: controlsDragging, dragOffset: $viewState.dragOffset))
                                
                                Buttons(currentTab: $currentTab)
                                    .padding(.top, 28)
                                    .padding(.horizontal, -28)
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 28)
                            .transition(.modifier(active: CollapseTransitionModifier(active: true), identity: CollapseTransitionModifier(active: false)))
                            .animation(.timingCurve(0.13, 1.21, 0.46, 0.79, duration: 0.5), value: controlsVisible)
                            .transaction {
                                guard $0.nowPlayingOverlayToggled else {
                                    return
                                }
                                
                                if presentedTrack == nil {
                                    $0.animation = .smooth
                                } else {
                                    $0.animation = .smooth.delay(0.1)
                                }
                            }
                        }
                    }
                }
                .zIndex(2)
                .environment(\.colorScheme, .light)
                .foregroundStyle(.white)
                .overlay(alignment: .top) {
                    if presentedTrack != nil {
                        Button {
                            viewState.setNowPlayingViewPresented(false)
                        } label: {
                            Rectangle()
                                .foregroundStyle(.thinMaterial)
                                .frame(width: 32, height: 4)
                                .clipShape(.rect(cornerRadius: .infinity))
                        }
                        .padding(40)
                        .modifier(GestureModifier(active: true, controlsDragging: controlsDragging, dragOffset: $viewState.dragOffset))
                        .padding(-40)
                        .transition(.opacity)
                        .transaction {
                            guard $0.nowPlayingOverlayToggled else {
                                return
                            }
                            
                            if presentedTrack == nil {
                                $0.animation = .smooth
                            } else {
                                $0.animation = .smooth.delay(0.3)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.safeAreaInsets.top)
                .offset(y: viewState.dragOffset)
                .allowsHitTesting(presentedTrack != nil)
                .persistentSystemOverlays(AudioPlayer.current.outputRoute.showLabel ? .hidden : .automatic)
                .onChange(of: currentTab) {
                    if currentTab == .cover {
                        controlsVisible = true
                    }
                }
            }
            .ignoresSafeArea(edges: .all)
            .environment(viewState)
            .modifier(Navigation.NavigationModifier() {
                viewState.setNowPlayingViewPresented(false)
            })
            .onAppear {
                viewState.namespace = namespace
            }
            .onChange(of: currentTab) {
                controlsVisible = true
            }
            .onChange(of: viewState.presented) {
                controlsVisible = true
            }
            .onChange(of: AudioPlayer.current.nowPlaying) { previous, current in
                if previous == nil {
                    viewState.setNowPlayingViewPresented(true)
                }
                
                if current == nil {
                    viewState.setNowPlayingViewPresented(false)
                }
            }
        }
    }
}

internal extension NowPlaying {
    @Observable
    final class CompactViewState {
        var namespace: Namespace.ID!
        var dragOffset: CGFloat = .zero
        
        private(set) var presented = false
        
        func setNowPlayingViewPresented(_ presented: Bool) {
            if presented {
                dragOffset = 0
            }
            
            UIApplication.shared.isIdleTimerDisabled = presented
            
            withTransaction(\.nowPlayingOverlayToggled, true) {
                withAnimation(presented ? .bouncy.delay(0.25) : .bouncy) {
                    self.presented = presented
                }
            }
        }
    }
}

private extension NowPlaying {
    struct GestureModifier: ViewModifier {
        @Environment(CompactViewState.self) private var viewState
        
        let active: Bool
        let controlsDragging: Bool
        
        @Binding var dragOffset: CGFloat
        
        func body(content: Content) -> some View {
            content
                .simultaneousGesture(
                    DragGesture(minimumDistance: active ? 0 : 1000, coordinateSpace: .global)
                        .onChanged {
                            guard !controlsDragging else {
                                return
                            }
                            
                            if $0.velocity.height > 3000 {
                                viewState.setNowPlayingViewPresented(false)
                            } else if $0.velocity.height < -3000 {
                                dragOffset = 0
                            } else {
                                dragOffset = max(0, $0.translation.height)
                            }
                        }
                        .onEnded {
                            if $0.translation.height > 200 && dragOffset != 0 {
                                viewState.setNowPlayingViewPresented(false)
                            } else {
                                dragOffset = 0
                            }
                        }
                )
        }
    }
}

private extension NowPlaying {
    struct BackgroundInsertTransitionModifier: ViewModifier {
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
    struct BackgroundRemoveTransitionModifier: ViewModifier {
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
    
    struct CollapseTransitionModifier: ViewModifier {
        let active: Bool
        
        func body(content: Content) -> some View {
            content
                .frame(height: active ? 0 : nil)
                .clipped()
        }
    }
}
