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
    
    @State private var track = AudioPlayer.current.nowPlaying
    @State private var viewState = NowPlayingViewState.init()
    @State private var playing = AudioPlayer.current.isPlaying()
    
    @State private var controlsVisible = true
    @State private var currentTab = Tab.cover
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .onAppear {
                    viewState.namespace = namespace
                }
                .environment(viewState)
                .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.trackChange), perform: { _ in
                    withAnimation {
                        track = AudioPlayer.current.nowPlaying
                    }
                })
                .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPause), perform: { _ in
                    withAnimation {
                        playing = AudioPlayer.current.isPlaying()
                    }
                })
                .onReceive(NotificationCenter.default.publisher(for: NavigationRoot.navigateNotification)) { _ in
                    viewState.setNowPlayingViewPresented(false)
                }
            
            if viewState.presented, let track = track {
                Color.clear
                    .background {
                        Background(cover: track.cover)
                            .id(track.id)
                            .transition(.move(edge: .bottom))
                            .matchedGeometryEffect(id: "nowPlaying", in: namespace, properties: .size, anchor: .top, isSource: viewState.presented == true)
                    }
                    .zIndex(2)
                
                VStack {
                    if currentTab == .cover {
                        Cover(track: track, currentTab: currentTab, namespace: namespace, playing: $playing)
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
                                    .push(from: .bottom).animation(.spring.delay(0.1))
                                    .combined(with: .opacity),
                            removal:
                                    .push(from: .top).animation(.spring.logicallyComplete(after: 0.1))
                                    .combined(with: .opacity)
                        ))
                    }
                    
                    if controlsVisible {
                        Controls(playing: $playing, currentTab: $currentTab)
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
                .gesture(
                    DragGesture(minimumDistance: 150).onEnded {
                        if $0.location.y - $0.startLocation.y > 150 {
                            viewState.setNowPlayingViewPresented(false)
                        }
                    }
                )
                .onChange(of: currentTab) {
                    if currentTab == .cover {
                        controlsVisible = true
                    }
                }
                // SwiftUI z-index is my new favorite worst piece of shit
                .zIndex(3)
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
                            
                            withAnimation(.spring(duration: 1)) {
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
        withAnimation(.spring(duration: 0.4)) {
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
