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
    
    let item: SongItem
    @Binding var playing: Bool
    
    @State var controlsVisible = true
    @State var currentTab = Tab.lyrics {
        didSet {
            if currentTab != .lyrics {
                controlsVisible = true
            }
        }
    }
    
    var body: some View {
        VStack {
            if currentTab == .cover {
                Cover(item: item, namespace: namespace, playing: $playing)
            } else {
                SmallTitle(item: item, namespace: namespace)
                
                if currentTab == .lyrics {
                    LyricsContainer(item: item, controlsVisible: $controlsVisible)
                }
            }
            
            if controlsVisible {
                Controls(playing: $playing, currentTab: $currentTab)
            }
        }
        .background(BackgroundImage(cover: item.cover))
        .padding(.horizontal, 30)
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .gesture(
            DragGesture().onEnded { value in
                if value.location.y - value.startLocation.y > 150 {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        )
    }
}

// MARK: Background

extension NowPlayingSheet {
    struct BackgroundImage: View {
        let cover: ItemCover?
        
        @State var imageOffset: CGFloat = 1
        
        var body: some View {
            // TODO: scale & random (moving) offset
            ItemImage(cover: cover)
                .offset(x: imageOffset * 50, y: imageOffset * -50)
                .rotationEffect(.degrees(imageOffset * 30))
                .frame(width: 1000, height: 1000)
                .overlay(.black.opacity(0.25))
                .blur(radius: 80)
                .onAppear {
                    withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                        imageOffset *= Double.random(in: 2..<6)
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
        .fullScreenCover(item: .constant(SongItem.fixture)) {
            NowPlayingSheet(item: $0, playing: .constant(false))
        }
}
