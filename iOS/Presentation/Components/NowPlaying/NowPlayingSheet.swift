//
//  NowPlayingSheet.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import UIImageColors
import FluidGradient
import AFBase

struct NowPlayingSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Namespace var namespace
    
    let track: Track
    let showDragIndicator: Bool
    
    @Binding var playing: Bool
    
    @State var controlsVisible = true
    @State var currentTab = Tab.cover
    
    var body: some View {
        VStack {
            if currentTab == .cover {
                Cover(track: track, namespace: namespace, playing: $playing)
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
                            .push(from: .bottom).animation(.easeIn.delay(0.1))
                            .combined(with: .opacity),
                    removal:
                            .push(from: .top).animation(.easeOut.logicallyComplete(after: 0.1))
                            .combined(with: .opacity)
                ))
            }
            
            if controlsVisible {
                Controls(playing: $playing, currentTab: $currentTab)
            }
        }
        .background {
            Background(cover: track.cover)
                .id(track.id)
        }
        .padding(.horizontal, 30)
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) {
            if showDragIndicator {
                Rectangle()
                    .foregroundStyle(.secondary)
                    .frame(width: 50, height: 7)
                    .clipShape(RoundedRectangle(cornerRadius: 10000))
                    .onTapGesture {
                        presentationMode.wrappedValue.dismiss()
                    }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 150).onEnded { value in
                if value.location.y - value.startLocation.y > 150 {
                    presentationMode.wrappedValue.dismiss()
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

// MARK: Background

extension NowPlayingSheet {
    struct Background: View {
        let cover: Item.Cover?
        
        @State var imageColors: ImageColors?
        
        var body: some View {
            ZStack {
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
        }
    }
}

// MARK: Tabs

extension NowPlayingSheet {
    enum Tab {
        case cover
        case lyrics
        case queue
    }
}

#Preview {
    Text(verbatim: ":)")
        .fullScreenCover(item: .constant(Track.fixture)) {
            NowPlayingSheet(track: $0, showDragIndicator: true, playing: .constant(false))
        }
}
