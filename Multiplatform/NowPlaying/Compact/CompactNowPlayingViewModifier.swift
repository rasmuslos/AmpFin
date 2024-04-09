//
//  NowPlayingView.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import UIImageColors
import AFBase
import AFPlayback

struct CompactNowPlayingViewModifier: ViewModifier {
    @Namespace var namespace
    
    @State private var viewState = NowPlayingViewState.init()
    
    @State private var controlsVisible = true
    @State private var currentTab = NowPlayingTab.cover
    
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
                .onAppear {
                    viewState.namespace = namespace
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateNotification)) { _ in
                    viewState.setNowPlayingViewPresented(false)
                }
            
            Group {
                if let track = presentedTrack {
                    NowPlayingBackground(cover: track.cover)
                        .zIndex(1)
                        .transition(.asymmetric(
                            insertion: .modifier(active: BackgroundInsertTransitionModifier(active: true), identity: BackgroundInsertTransitionModifier(active: false)),
                            removal: .modifier(active: BackgroundRemoveTransitionModifier(active: true), identity: BackgroundRemoveTransitionModifier(active: false)))
                        )
                }
                
                if viewState.containerPresented {
                    VStack {
                        if let track = presentedTrack {
                            if currentTab == .cover {
                                NowPlayingCover(track: track, currentTab: currentTab, namespace: namespace)
                            } else {
                                NowPlayingSmallTitle(track: track, namespace: namespace, currentTab: $currentTab)
                                
                                Group {
                                    if currentTab == .lyrics {
                                        NowPlayingLyricsContainer(controlsVisible: $controlsVisible)
                                    } else if currentTab == .queue {
                                        NowPlayingQueue()
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
                                    NowPlayingControls(controlsDragging: $controlsDragging)
                                    NowPlayingButtons(currentTab: $currentTab)
                                        .padding(.bottom, 40)
                                }
                                .transition(.move(edge: .bottom).animation(.linear(duration: 0.3)))
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
                                    .foregroundStyle(.white.secondary.opacity(0.75))
                                    .frame(width: 50, height: 7)
                                    .clipShape(RoundedRectangle(cornerRadius: 10000))
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.animation(.linear(duration: 0.1).delay(0.3)),
                                removal: .opacity.animation(.linear(duration: 0.1))))
                        }
                    }
                    .padding(.horizontal, 30)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 25, coordinateSpace: .global)
                            .onChanged {
                                if controlsDragging {
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
                    .onChange(of: currentTab) {
                        if currentTab == .cover {
                            controlsVisible = true
                        }
                    }
                }
            }
            .allowsHitTesting(presentedTrack != nil)
            // This is very reasonable and sane
            .padding(.top, UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.safeAreaInsets.top)
            .frame(height: UIScreen.main.bounds.height)
            .offset(y: dragOffset)
            .animation(.spring, value: dragOffset)
        }
        // why does this work? only god knows...
        .ignoresSafeArea(edges: .all)
        .environment(viewState)
    }
}

struct BackgroundInsertTransitionModifier: ViewModifier {
    @Environment(NowPlayingViewState.self) private var viewState
    
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .mask(alignment: .bottom) {
                Rectangle()
                    .frame(width: UIScreen.main.bounds.width - (active ? 24 : 0), height: active ? 0 : UIScreen.main.bounds.height)
            }
            .offset(y: active ? -146 : 0)
    }
}

// This is more a "collapse" than a move thing
struct BackgroundRemoveTransitionModifier: ViewModifier {
    @Environment(NowPlayingViewState.self) private var viewState
    
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .mask(alignment: .bottom) {
                Rectangle()
                    .frame(width: UIScreen.main.bounds.width - (active ? 24 : 0), height: active ? 0 : UIScreen.main.bounds.height)
                    .animation(.easeOut(duration: 0.4), value: active)
            }
            .offset(y: active ? -92 : 0)
    }
}

// MARK: Background

@Observable
class NowPlayingViewState {
    var namespace: Namespace.ID!
    
    private(set) var presented = false
    private(set) var containerPresented = false
    
    private(set) var active = false
    private(set) var lastActive = Date()
    
    func setNowPlayingViewPresented(_ presented: Bool, completion: (() -> Void)? = nil) {
        if active && lastActive.timeIntervalSince(Date()) > -1 {
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
