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
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                
            }
            
            if let track = AudioPlayer.current.nowPlaying {
                NowPlayingBackground(cover: track.cover)
                    .clipped()
                
                VStack {
                    HStack {
                        VStack {
                            NowPlayingCover(track: track, currentTab: currentTab, namespace: namespace)
                            NowPlayingControls(controlsDragging: $controlsDragging)
                            
                            Spacer()
                        }
                        .frame(maxWidth: 475)
                        
                        if currentTab != .cover {
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
                .padding(.bottom)
                .padding(.horizontal, 40)
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
                #if targetEnvironment(macCatalyst)
                .toolbar(.hidden, for: .tabBar)
                .toolbar(.hidden, for: .bottomBar)
                .toolbar(.hidden, for: .navigationBar)
                #endif
            }
        }
    }
}

#Preview {
    RegularNowPlayingView()
}
