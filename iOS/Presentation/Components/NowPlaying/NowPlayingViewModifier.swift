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
    
    @State private var dragOffset: CGFloat = .zero
    
    func body(content: Content) -> some View {
        ZStack {
            content
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
                        .id(track.id)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            dragOffset = 0
                        }
                        .onDisappear {
                            dragOffset = 0
                        }
                        .zIndex(2)
                    
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
                            Controls(currentTab: $currentTab)
                        }
                    }
                    .foregroundStyle(.white)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .foregroundStyle(.white.secondary.opacity(0.75))
                            .frame(width: 50, height: 7)
                            .clipShape(RoundedRectangle(cornerRadius: 10000))
                            .onTapGesture {
                                viewState.setNowPlayingViewPresented(false)
                            }
                    }
                    .padding(.horizontal, 30)
                    .ignoresSafeArea(edges: .bottom)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 25, coordinateSpace: .global)
                            .onChanged {
                                dragOffset = max(0, $0.translation.height)
                            }
                            .onEnded {
                                if $0.location.y - $0.startLocation.y > 200 {
                                    viewState.setNowPlayingViewPresented(false)
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
                    .zIndex(3)
                }
                // SwiftUI z-index is my new favorite worst piece of shit
                // This is very reasonable and sane
                .padding(.top, UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.safeAreaInsets.top)
                .frame(height: UIScreen.main.bounds.height)
                .offset(y: dragOffset)
                .animation(.interactiveSpring, value: dragOffset)
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
                    .blur(radius: 100)
                    .frame(width: 1000, height: 1000)
                
                if let imageColors = imageColors {
                    FluidGradient(blobs: [imageColors.background, imageColors.detail, imageColors.primary, imageColors.secondary], speed: CGFloat.random(in: 0.2...0.4), blur: 0.8)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height + 100)
                        .overlay(.black.opacity(0.25))
                } else {
                    Color.clear
                        .task(priority: .medium) {
                            let imageColors = await ImageColors.getImageColors(cover: cover)
                            imageColors?.updateHue(saturation: 0.6, luminance: 0.6)
                            
                            withAnimation(.easeInOut(duration: 1)) {
                                self.imageColors = imageColors
                            }
                        }
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
    }
}

@Observable
class NowPlayingViewState {
    var namespace: Namespace.ID!
    private(set) var presented = false
    
    func setNowPlayingViewPresented(_ presented: Bool) {
        withAnimation(.interactiveSpring(duration: 0.7, extraBounce: 0.1)) {
            self.presented = presented
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
