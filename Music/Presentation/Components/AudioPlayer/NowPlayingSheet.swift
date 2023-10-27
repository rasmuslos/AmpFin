//
//  NowPlayingSheet.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import UIImageColors

struct NowPlayingSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Namespace var namespace
    
    // i have no fucking idea why this updates
    let track: Track
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
        .background(BackgroundImage(cover: track.cover))
        .padding(.horizontal, 30)
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) {
            Rectangle()
                .foregroundStyle(.secondary)
                .frame(width: 50, height: 7)
                .clipShape(RoundedRectangle(cornerRadius: 10000))
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
    struct BackgroundImage: View {
        let cover: Item.Cover?
        
        @State var imageOffset: CGFloat = 1
        
        var body: some View {
            ItemImage(cover: cover)
                .offset(x: imageOffset * 25, y: imageOffset * -25)
                .rotationEffect(.degrees(imageOffset * 30))
                .frame(width: 1000, height: 1000)
                .overlay(.black.opacity(0.25))
                .blur(radius: 80)
                .onAppear {
                    withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                        imageOffset *= Double.random(in: -6..<6)
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
    Text(":)")
        .fullScreenCover(item: .constant(Track.fixture)) {
            NowPlayingSheet(track: $0, playing: .constant(false))
        }
}
