//
//  NowPlayingView.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import UIImageColors
import FluidGradient
import AFBase
import AFPlayback

struct NowPlayingViewModifier: ViewModifier {
    @Namespace var namespace
    
    @State private var viewState = NowPlayingViewState.init()
    
    @State private var controlsVisible = true
    @State private var currentTab = Tab.cover
    
    @State private var controlsDragging = false
    @State private var dragOffset: CGFloat = .zero
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var presentedTrack: Track? {
        if viewState.presented, let track = AudioPlayer.current.nowPlaying {
            return track
        }
        
        return nil
    }
    
    private var useHorizontalLayout: Bool {
        if horizontalSizeClass == .regular {
            return true
        }
        return false
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .allowsHitTesting(!viewState.presented)
                .onAppear {
                    viewState.namespace = namespace
                }
                .onReceive(NotificationCenter.default.publisher(for: NavigationRoot.navigateNotification)) { _ in
                    viewState.setNowPlayingViewPresented(false)
                }
            
            Group {
                if let track = presentedTrack {
                    Background(cover: track.cover)
                        // SwiftUI z-index is my new favorite worst piece of shit
                        .zIndex(1)
                        .transition(.asymmetric(
                            insertion: .modifier(active: BackgroundInsertTransitionModifier(active: true), identity: BackgroundInsertTransitionModifier(active: false)),
                            removal: .modifier(active: BackgroundRemoveTransitionModifier(active: true), identity: BackgroundRemoveTransitionModifier(active: false)))
                        )
                        .onAppear {
                            dragOffset = 0
                        }
                }
                
                if viewState.containerPresented {
                    HStack {
                        VStack{
                            if let track = presentedTrack {
                                if useHorizontalLayout || currentTab == .cover {
                                    Cover(track: track, currentTab: currentTab, namespace: namespace)
                                } else {
                                    SmallTitle(track: track, namespace: namespace, currentTab: $currentTab)
                                    Group {
                                        if currentTab == .lyrics {
                                            LyricsContainer(controlsVisible: $controlsVisible)
                                        } else if currentTab == .queue {
                                            Queue()
                                                .padding(.horizontal, -30)
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
                                    Controls(currentTab: $currentTab, controlsDragging: $controlsDragging)
                                        .transition(.move(edge: .bottom).animation(.linear(duration: 0.3)))
                                }
                            }
                        }
                        .frame(maxWidth: 500)
                        if useHorizontalLayout, viewState.presented {
                            VStack{
                                Group {
                                    if currentTab == .lyrics {
                                        LyricsContainer(controlsVisible: $controlsVisible)
                                    } else if currentTab == .queue {
                                        Queue()
                                            .padding(.vertical, 10)
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
                            .transition(.move(edge: .bottom).animation(.linear(duration: 0.2)))
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
            }
    }
}

// MARK: Background

extension NowPlayingViewModifier {
    struct Background: View {
        let cover: Item.Cover?
        
        @State var imageColors: ImageColors?
        
        var body: some View {
            ZStack {
                Color.black
                
                ItemImage(cover: cover)
                    .id(cover?.url)
                    .blur(radius: 100)
                
                if let imageColors = imageColors {
                    FluidGradient(blobs: [imageColors.background, imageColors.detail, imageColors.primary, imageColors.secondary], speed: CGFloat.random(in: 0.2...0.4), blur: 0.8)
                        .onChange(of: cover?.url) { determineImageColors() }
                } else {
                    Color.clear
                        .onAppear { determineImageColors() }
                }
            }
            .overlay(.black.opacity(0.25))
            .ignoresSafeArea(edges: .all)
            .allowsHitTesting(false)
        }
        
        func determineImageColors() {
            Task.detached {
                let imageColors = await ImageColors.getImageColors(cover: cover)
                imageColors?.updateHue(saturation: 0.6, luminance: 0.6)
                
                withAnimation(.easeInOut(duration: 1)) {
                    self.imageColors = imageColors
                }
            }
        }
    }
}

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

// MARK: Tabs

extension NowPlayingViewModifier {
    enum Tab {
        case cover
        case lyrics
        case queue
    }
}
