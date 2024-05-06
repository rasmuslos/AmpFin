//
//  RegularNowPlayingCover.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AFBase
import AFPlayback

extension NowPlaying {
    struct RegularView: View {
        @Namespace private var namespace
        @Environment(\.dismiss) var dismiss
        
        @State private var availableWidth: CGFloat = .zero
        
        @State private var controlsDragging = false
        @State private var currentTab = Tab.cover
        
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
                    Background(cover: track.cover, dragging: false)
                        .clipped()
                    
                    VStack {
                        HStack {
                            VStack {
                                // Single column layout
                                if !singleColumnLayout || currentTab == .cover {
                                    Cover(track: track, currentTab: currentTab, namespace: namespace)
                                } else {
                                    SmallTitle(track: track, namespace: namespace, currentTab: $currentTab)
                                    
                                    Group {
                                        if currentTab == .lyrics {
                                            Lyrics(controlsVisible: .constant(false))
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
                                
                                Controls(compact: !singleColumnLayout, controlsDragging: $controlsDragging)
                                    .padding(.bottom, 30)
                            }
                            .frame(maxWidth: singleColumnLayout ? .infinity : 475)
                            
                            // Two column layout
                            if !singleColumnLayout && currentTab != .cover {
                                VStack {
                                    Group {
                                        if currentTab == .queue {
                                            Queue()
                                        } else if currentTab == .lyrics {
                                            Lyrics(controlsVisible: .constant(false))
                                        }
                                    }
                                    .transition(.blurReplace)
                                }
                                .padding(.leading, 80)
                                .transition(.move(edge: .trailing))
                            }
                        }
                        
                        Buttons(currentTab: $currentTab)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 25, coordinateSpace: .global)
                            .onEnded {
                                if $0.translation.height > 200 {
                                    dismiss()
                                }
                            }
                    )
                    .padding(.bottom, singleColumnLayout ? 30 : 20)
                    .padding(.horizontal, singleColumnLayout ? 60 : 40)
                    .padding(.top, 60)
                    .ignoresSafeArea(edges: .all)
                    .foregroundStyle(.white)
                    .overlay(alignment: .top) {
                        Button {
                            dismiss()
                        } label: {
                            Rectangle()
                                .foregroundStyle(.white.secondary.opacity(0.75))
                                .frame(width: 50, height: 7)
                                .clipShape(RoundedRectangle(cornerRadius: 10000))
                        }
                        .modifier(ButtonHoverEffectModifier(hoverEffect: .lift))
                        .padding(.top, 35)
                    }
                    .modifier(Navigation.NavigationModifier() {
                        dismiss()
                    })
                }
            }
        }
    }
}
