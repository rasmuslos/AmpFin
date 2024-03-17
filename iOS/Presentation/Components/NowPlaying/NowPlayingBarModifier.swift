//
//  NowPlayingBar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AFBase
import AFPlayback

// For some fucking reason animations do not work on `NavigationStack`, so this has to be added to every view... WHY?

struct NowPlayingBarModifier: ViewModifier {
    @Environment(NowPlayingViewState.self) private var nowPlayingViewState
    @Environment(\.libraryDataProvider) private var dataProvider
    
    @State var playing = AudioPlayer.current.isPlaying()
    @State var currentTrack = AudioPlayer.current.nowPlaying
    
    @State private var animateImage = false
    @State private var animateForwards = false
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if !nowPlayingViewState.presented, let currentTrack = currentTrack {
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .frame(width: UIScreen.main.bounds.width + 100, height: 300)
                            .padding(.bottom, -225)
                            .blur(radius: 25)
                            .foregroundStyle(.thinMaterial)
                        
                        RoundedRectangle(cornerRadius: 15)
                            .toolbarBackground(.hidden, for: .tabBar)
                            .foregroundStyle(.ultraThinMaterial)
                            .matchedGeometryEffect(id: "nowPlaying", in: nowPlayingViewState.namespace, properties: .position, anchor: .center, isSource: nowPlayingViewState.presented != true)
                            .transition(.opacity.animation(.spring(duration: 0.1)))
                            .overlay {
                                HStack {
                                    ItemImage(cover: currentTrack.cover)
                                        .frame(width: 40, height: 40)
                                        .padding(.leading, 5)
                                        .matchedGeometryEffect(id: "image", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottomLeading, isSource: !nowPlayingViewState.presented)
                                    
                                    Text(currentTrack.name)
                                        .lineLimit(1)
                                        .matchedGeometryEffect(id: "title", in: nowPlayingViewState.namespace, properties: .frame, anchor: .bottom, isSource: !nowPlayingViewState.presented)
                                    
                                    Spacer()
                                    
                                    Group {
                                        Button {
                                            AudioPlayer.current.setPlaying(!playing)
                                        } label: {
                                            Image(systemName: playing ?  "pause.fill" : "play.fill")
                                                .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                                .scaleEffect(animateImage ? AudioPlayer.current.isPlaying() ? 1.1 : 0.9 : 1)
                                                .animation(.spring(duration: 0.2, bounce: 0.7), value: animateImage)
                                                .onChange(of: AudioPlayer.playPause) {
                                                    withAnimation {
                                                        animateImage = true
                                                    } completion: {
                                                        animateImage = false
                                                    }
                                                }
                                        }
                                        
                                        Button {
                                            animateForwards.toggle()
                                            AudioPlayer.current.advanceToNextTrack()
                                        } label: {
                                            Image(systemName: "forward.fill")
                                                .symbolEffect(.bounce.up, value: animateForwards)
                                        }
                                        .padding(.horizontal, 10)
                                    }
                                    .imageScale(.large)
                                }
                                .padding(.horizontal, 6)
                                .transition(.asymmetric(
                                    insertion: .opacity.animation(.spring(duration: 0.1).delay(0.2)),
                                    removal: .opacity.animation(.spring(duration: 0.1))))
                            }
                            .foregroundStyle(.primary)
                            .frame(width: UIScreen.main.bounds.width - 30, height: 60)
                            .shadow(color: .black.opacity(0.25), radius: 20)
                            .draggable(currentTrack) {
                                TrackListRow.TrackPreview(track: currentTrack)
                            }
                            .modifier(ContextMenuModifier(track: currentTrack, animateForwards: $animateForwards))
                            .padding(.bottom, 10)
                            .onTapGesture {
                                nowPlayingViewState.setNowPlayingViewPresented(true)
                            }
                    }
                }
            }
            .dropDestination(for: Track.self) { tracks, _ in
                AudioPlayer.current.queueTracks(tracks, index: 0)
                return true
            }
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.trackChange), perform: { _ in
                withAnimation {
                    currentTrack = AudioPlayer.current.nowPlaying
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPause), perform: { _ in
                withAnimation {
                    playing = AudioPlayer.current.isPlaying()
                }
            })
    }
}

#Preview {
    TabView {
        NavigationStack {
            Rectangle()
                .foregroundStyle(.red)
                .ignoresSafeArea()
                .modifier(NowPlayingBarModifier(playing: true, currentTrack: Track.fixture))
        }
        .tabItem { Label(":)", systemImage: "command") }
    }
    .modifier(NowPlayingViewModifier())
}
