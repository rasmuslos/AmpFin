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
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .allowsHitTesting(!viewState.presented)
                .onAppear {
                    viewState.namespace = namespace
                }
                .environment(viewState)
                .onReceive(NotificationCenter.default.publisher(for: NavigationRoot.navigateNotification)) { _ in
                    viewState.setNowPlayingViewPresented(false)
                }
            
            if viewState.presented, let track = AudioPlayer.current.nowPlaying {
                Group {
                    Background(cover: track.cover)
                        .zIndex(4)
                        .transition(.move(edge: .bottom).combined(with: .opacity(min: 0.2)))
                    
                    VStack {
                        if currentTab == .cover {
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
                        }
                    }
                    .foregroundStyle(.white)
                    .overlay(alignment: .top) {
                        Button {
                            viewState.setNowPlayingViewPresented(false)
                        } label: {
                            Rectangle()
                                .foregroundStyle(.white.secondary.opacity(0.75))
                                .frame(width: 50, height: 7)
                                .clipShape(RoundedRectangle(cornerRadius: 10000))
                        }
                        .transition(.opacity.animation(.linear(duration: 0.1)))
                    }
                    .padding(.horizontal, 30)
                    .ignoresSafeArea(edges: .bottom)
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
                    .zIndex(5)
                }
                // SwiftUI z-index is my new favorite worst piece of shit
                // This is very reasonable and sane
                .padding(.top, UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.safeAreaInsets.top)
                .frame(height: UIScreen.main.bounds.height)
                .offset(y: dragOffset)
                .animation(.spring, value: dragOffset)
            }
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
                    .frame(width: 1000, height: 1000)
                
                if let imageColors = imageColors {
                    FluidGradient(blobs: [imageColors.background, imageColors.detail, imageColors.primary, imageColors.secondary], speed: CGFloat.random(in: 0.2...0.4), blur: 0.8)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height + 100)
                        .onChange(of: cover?.url) { determineImageColors() }
                } else {
                    Color.clear
                        .onAppear { determineImageColors() }
                }
            }
            .overlay(.black.opacity(0.25))
            .ignoresSafeArea(edges: .all)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
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
    
    func setNowPlayingViewPresented(_ presented: Bool, completion: (() -> Void)? = nil) {
        withAnimation(.spring(duration: 0.6, bounce: 0.1)) {
            self.presented = presented
        } completion: {
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
