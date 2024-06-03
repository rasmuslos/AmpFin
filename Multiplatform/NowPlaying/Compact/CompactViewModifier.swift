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
                    .modifier(Navigation.NavigationModifier() {
                        viewState.setNowPlayingViewPresented(false)
                    })
                    .onAppear {
                        viewState.namespace = namespace
                    }
                    .onChange(of: AudioPlayer.current.nowPlaying) { previous, current in
                        guard previous == nil && current != nil else {
                            return
                        }
                        
                        viewState.setNowPlayingViewPresented(true)
                    }
                
                Group {
                    if let track = presentedTrack {
                        Background(cover: track.cover, dragging: dragOffset != 0)
                            .zIndex(1)
                            .transition(.asymmetric(
                                insertion: .modifier(active: BackgroundInsertTransitionModifier(active: true), identity: BackgroundInsertTransitionModifier(active: false)),
                                removal: .modifier(active: BackgroundRemoveTransitionModifier(active: true), identity: BackgroundRemoveTransitionModifier(active: false)))
                            )
                            .onAppear {
                                // In rare cases, this value is not set to 0 on closing.
                                // Forcing a reset to 0 on appearance to prevent strange animations
                                // where the container appears halfway on the screen.
                                dragOffset = 0
                            }
                    }
                    
                    if viewState.containerPresented {
                        VStack {
                            if let track = presentedTrack {
                                if currentTab == .cover {
                                    LargeTitle(track: track, currentTab: currentTab, namespace: namespace)
                                        .modifier(GestureModifier(active: currentTab == .cover, controlsDragging: controlsDragging, dragOffset: $dragOffset))
                                } else {
                                    SmallTitle(track: track, namespace: namespace, currentTab: $currentTab)
                                        .transition(.opacity.animation(.linear(duration: 0.1)))
                                        .modifier(GestureModifier(active: true, controlsDragging: controlsDragging, dragOffset: $dragOffset))
                                        .padding(.top, 40)
                                    
                                    Group {
                                        if currentTab == .lyrics {
                                            Lyrics(controlsVisible: $controlsVisible)
                                        } else if currentTab == .queue {
                                            Queue()
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion:
                                                .push(from: .bottom).animation(.spring.delay(0.2))
                                                .combined(with: .opacity),
                                        removal:
                                                .push(from: .top).animation(.spring.logicallyComplete(after: 0.1))
                                                .combined(with: .opacity)
                                    ))
                                }
                                
                                if controlsVisible {
                                    Group {
                                        Controls(compact: false, controlsDragging: $controlsDragging)
                                            .padding(.top, 12)
                                            .modifier(GestureModifier(active: currentTab == .cover, controlsDragging: controlsDragging, dragOffset: $dragOffset))
                                        Buttons(currentTab: $currentTab)
                                            .padding(.top, 20)
                                            .padding(.bottom, 28)
                                            .padding(.horizontal, -28)
                                    }
                                    .transition(.modifier(
                                        active: CollapseTransitionModifier(active: true),
                                        identity: CollapseTransitionModifier(active: false)))
                                }
                            }
                        }
                        .zIndex(2)
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
                                .modifier(GestureModifier(active: true, controlsDragging: controlsDragging, dragOffset: $dragOffset))
                                .padding(-40)
                                .transition(.asymmetric(
                                    insertion: .opacity.animation(.linear(duration: 0.1).delay(0.3)),
                                    removal: .opacity.animation(.linear(duration: 0.05))))
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.safeAreaInsets.top)
                        .environment(\.colorScheme, .light)
                        .onChange(of: currentTab) {
                            dragOffset = 0
                            
                            if currentTab == .cover {
                                controlsVisible = true
                            }
                        }
                    }
                }
                .allowsHitTesting(presentedTrack != nil)
                .offset(y: dragOffset)
            }
            .ignoresSafeArea(edges: .all)
            .environment(viewState)
            .onChange(of: viewState.presented) {
                controlsVisible = true
            }
            .onChange(of: currentTab) {
                controlsVisible = true
            }
        }
    }
}

internal extension NowPlaying {
    @Observable
    final class CompactViewState {
        var namespace: Namespace.ID!
        
        private(set) var presented = false
        private(set) var containerPresented = false
        
        private(set) var active = false
        private(set) var lastActive = Date()
        
        func setNowPlayingViewPresented(_ presented: Bool, completion: (() -> Void)? = nil) {
            guard !active && lastActive.timeIntervalSince(Date()) <= -1 else {
                return
            }
            
            active = true
            lastActive = Date()
            
            if presented {
                containerPresented = true
            }
            
            withAnimation(.spring(duration: 0.6, bounce: 0.1)) {
                self.presented = presented
            } completion: {
                self.active = false
                
                if !self.presented {
                    self.containerPresented = false
                }
                
                completion?()
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
                                viewState.setNowPlayingViewPresented(false) {
                                    dragOffset = 0
                                }
                            } else if $0.velocity.height < -3000 {
                                dragOffset = 0
                            } else {
                                dragOffset = max(0, $0.translation.height)
                            }
                        }
                        .onEnded {
                            if $0.translation.height > 200 && dragOffset != 0 {
                                viewState.setNowPlayingViewPresented(false) {
                                    dragOffset = 0
                                }
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
                }
                .offset(y: active ? -146 : 0)
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
                        .animation(Animation.smooth(duration: 0.5, extraBounce: 0.1), value: active)
                }
                .offset(y: active ? -92 : 0)
        }
    }
    
    struct CollapseTransitionModifier: ViewModifier {
        let active: Bool
        
        func body(content: Content) -> some View {
            content
                .frame(height: active ? 0 : nil)
                .animation(.spring(duration: 0.1), value: active)
        }
    }
}
