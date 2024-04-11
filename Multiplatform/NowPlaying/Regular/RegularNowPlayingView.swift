//
//  RegularNowPlayingCover.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AFBase
import AFPlayback

struct RegularNowPlayingView: View {
    @Namespace private var namespace
    @Environment(\.dismiss) var dismiss
    
    @State private var availableWidth: CGFloat = .zero
    
    @State private var controlsDragging = false
    @State private var currentTab = NowPlayingTab.cover
    
    private var singleColumnLayout: Bool {
        availableWidth < 1050
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        availableWidth = proxy.size.width
                    }
                    .onChange(of: proxy.size.width) {
                        availableWidth = proxy.size.width
                    }
            }
            .frame(height: 0)
            
            if let track = AudioPlayer.current.nowPlaying {
                NowPlayingBackground(cover: track.cover)
                    .clipped()
                
                VStack {
                    HStack {
                        VStack {
                            // Single column layout
                            if !singleColumnLayout || currentTab == .cover {
                                NowPlayingCover(track: track, currentTab: currentTab, namespace: namespace)
                            } else {
                                NowPlayingSmallTitle(track: track, namespace: namespace, currentTab: $currentTab)
                                
                                Group {
                                    if currentTab == .lyrics {
                                        NowPlayingLyricsContainer(controlsVisible: .constant(true))
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
                            
                            NowPlayingControls(compact: !singleColumnLayout, controlsDragging: $controlsDragging)
                                .padding(.bottom, 30)
                        }
                        .frame(maxWidth: singleColumnLayout ? .infinity : 475)
                        
                        // Two column layout
                        if !singleColumnLayout && currentTab != .cover {
                            VStack {
                                Group {
                                    if currentTab == .queue {
                                        NowPlayingQueue()
                                    } else if currentTab == .lyrics {
                                        NowPlayingLyricsContainer(controlsVisible: .constant(false))
                                    }
                                }
                                .transition(.blurReplace)
                            }
                            .padding(.leading, 80)
                            .transition(.move(edge: .trailing))
                        }
                    }
                    
                    NowPlayingButtons(currentTab: $currentTab)
                }
                .padding(.bottom, singleColumnLayout ? 30 : 20)
                .padding(.horizontal, singleColumnLayout ? 60 : 40)
                .padding(.top, 60)
                .ignoresSafeArea(edges: .all)
                .foregroundStyle(.white)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 25, coordinateSpace: .global)
                        .onEnded {
                            if $0.translation.height > 200 {
                                dismiss()
                            }
                        }
                )
                .overlay(alignment: .top) {
                    Button {
                        dismiss()
                    } label: {
                        Rectangle()
                            .foregroundStyle(.white.secondary.opacity(0.75))
                            .frame(width: 50, height: 7)
                            .clipShape(RoundedRectangle(cornerRadius: 10000))
                    }
                    .padding(.top, 35)
                }
            }
        }
    }
}

#Preview {
    RegularNowPlayingView()
}
