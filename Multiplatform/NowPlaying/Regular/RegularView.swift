//
//  RegularNowPlayingCover.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    struct RegularView: View {
        @Environment(ViewModel.self) private var viewModel
        @Environment(\.dismiss) private var dismiss
        
        @State private var availableWidth: CGFloat = .zero
        
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
                
                if let track = viewModel.nowPlaying {
                    Background()
                    
                    VStack {
                        HStack {
                            VStack {
                                // Single column layout
                                if !singleColumnLayout || viewModel.currentTab == .cover {
                                    LargeTitle(track: track)
                                } else {
                                    SmallTitle(track: track)
                                        .padding(.top, 40)
                                    
                                    Group {
                                        if viewModel.currentTab == .lyrics {
                                            Lyrics()
                                        } else if viewModel.currentTab == .queue {
                                            Queue()
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
                                
                                Controls(compact: !singleColumnLayout)
                                    .padding(.top, 12)
                                    .padding(.bottom, 32)
                            }
                            .frame(maxWidth: singleColumnLayout ? .infinity : 475)
                            
                            // Two column layout
                            if !singleColumnLayout && viewModel.currentTab != .cover {
                                VStack {
                                    Group {
                                        if viewModel.currentTab == .queue {
                                            Queue()
                                        } else if viewModel.currentTab == .lyrics {
                                            Lyrics()
                                        }
                                    }
                                    .transition(.blurReplace)
                                }
                                .padding(.leading, 80)
                                .padding(.top, viewModel.currentTab == .queue ? 62 : 0)
                                .transition(.move(edge: .trailing))
                            }
                        }
                        
                        Buttons()
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
