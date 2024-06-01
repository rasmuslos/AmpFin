//
//  RegularNowPlayingCover.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback

extension NowPlaying {
    struct RegularView: View {
        @Namespace private var namespace
        @Environment(\.dismiss) private var dismiss
        
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
                        .onChange(of: proxy.size.width, initial: true) {
                            availableWidth = proxy.size.width
                        }
                }
                .frame(height: 0)
                
                if let track = AudioPlayer.current.nowPlaying {
                    Background(cover: track.cover, dragging: false)
                    
                    VStack {
                        HStack {
                            VStack {
                                // Single column layout
                                if !singleColumnLayout || currentTab == .cover {
                                    LargeTitle(track: track, currentTab: currentTab, namespace: namespace)
                                } else {
                                    SmallTitle(track: track, namespace: namespace, currentTab: $currentTab)
                                        .padding(.top, 40)
                                    
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
                                    .padding(.top, 12)
                                    .padding(.bottom, 32)
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
                                .padding(.top, currentTab == .queue ? 62 : 0)
                                .transition(.move(edge: .trailing))
                            }
                        }
                        
                        Buttons(currentTab: $currentTab)
                    }
                    .foregroundStyle(.white)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 25, coordinateSpace: .global)
                            .onEnded {
                                if $0.translation.height > 200 {
                                    dismiss()
                                }
                            }
                    )
                    .padding(.bottom, singleColumnLayout ? 32 : 20)
                    .padding(.horizontal, singleColumnLayout ? 62 : 40)
                    .padding(.top, 40)
                    // this has to be here!
                    .ignoresSafeArea(edges: .all)
                    .overlay(alignment: .top) {
                        Button {
                            dismiss()
                        } label: {
                            Rectangle()
                                .foregroundStyle(.thinMaterial)
                                .frame(width: 52, height: 8)
                                .clipShape(.rect(cornerRadius: .infinity))
                        }
                        .modifier(HoverEffectModifier(hoverEffect: .lift))
                        .padding(.top, 36)
                    }
                    .environment(\.colorScheme, .light)
                    .modifier(Navigation.NavigationModifier() {
                        dismiss()
                    })
                }
            }
        }
    }
}
