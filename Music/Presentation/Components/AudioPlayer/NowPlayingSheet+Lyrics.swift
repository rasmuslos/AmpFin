//
//  NowPlayingSheet+Lyrics.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

// MARK: Container

extension NowPlayingSheet {
    struct LyricsContainer: View {
        let track: Track
        @Binding var controlsVisible: Bool
        
        @State var lyrics: Track.Lyrics?
        @State var activeLineIndex: Int = 0
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if let lyrics = lyrics {
                        LazyVStack {
                            ForEach(Array(lyrics.keys.sorted(by: <).enumerated()), id: \.offset) { index, key in
                                LyricLine(index: index, text: lyrics[key]!, activeLineIndex: $activeLineIndex)
                                    .onTapGesture {
                                        AudioPlayer.shared.seek(seconds: Array(lyrics.keys.sorted(by: <))[index])
                                        activeLineIndex = index
                                    }
                            }
                        }
                        .padding(.vertical, 25)
                        .safeAreaPadding(.bottom, 175)
                    } else {
                        ProgressView()
                            .padding(.vertical, 50)
                    }
                }
                .mask(
                    VStack(spacing: 0) {
                        LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                            .frame(height: 60)
                        
                        Rectangle().fill(Color.black)
                        
                        LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                            .frame(height: 60)
                    }
                )
                .onChange(of: activeLineIndex) {
                    withAnimation(.spring) {
                        proxy.scrollTo(activeLineIndex, anchor: .top)
                    }
                }
                .simultaneousGesture(
                    DragGesture().onChanged({ gesture in
                        if 0 < gesture.translation.height {
                            controlsVisible = true
                        } else {
                            controlsVisible = false
                        }
                    }))
            }
            .onAppear(perform: fetchLyrics)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.TrackChange), perform: { _ in
                fetchLyrics()
            })
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.PositionUpdated), perform: { _ in
                updateLyricsIndex()
            })
        }
        
        // MARK: Helper
        
        func updateLyricsIndex() {
            if let lyrics = lyrics, lyrics.count > activeLineIndex + 1 {
                let seconds = Array(lyrics.keys).sorted(by: <)[activeLineIndex + 1]
                
                if seconds < AudioPlayer.shared.currentTime() {
                    activeLineIndex += 1
                    updateLyricsIndex()
                }
            }
        }
        
        func fetchLyrics() {
            Task.detached {
                lyrics = try? await JellyfinClient.shared.getLyrics(trackId: track.id)
            }
        }
    }
}

// MARK: Line

extension NowPlayingSheet {
    struct LyricLine: View {
        let index: Int
        let text: String?
        
        @Binding var activeLineIndex: Int
        
        @State var pulse: CGFloat = 1
        
        var body: some View {
            let active = index == activeLineIndex
            
            HStack {
                if let text = text {
                    Text(text)
                        .font(.system(size: 35))
                    
                    Spacer()
                } else if active {
                    HStack {
                        Circle()
                            .frame(width: 15)
                            .scaleEffect(pulse)
                        Circle()
                            .frame(width: 15)
                            .scaleEffect(pulse)
                        Circle()
                            .frame(width: 15)
                            .scaleEffect(pulse)
                    }
                    .padding(.leading, pulse * 2)
                    
                    Spacer()
                }
            }
            .fontWeight(.heavy)
            .foregroundStyle(.white.opacity(active ? 0.9 : 0.25))
            .blur(radius: active ? 0 : 2)
            .tag(activeLineIndex)
            .animation(.spring, value: active)
            .animation(.easeInOut(duration: 0.5).delay(active ? 0.25 : Double(index - activeLineIndex) / 7), value: activeLineIndex)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulse *= 1.2
                }
            }
            .padding(.vertical, 10)
            .offset(y: 25 + determineAdditionalOffset())
        }
        
        func determineAdditionalOffset() -> CGFloat {
            let delta = index - activeLineIndex
            
            if delta < 0 {
                return 0
            }
            
            switch delta {
            case 0, 1, 2, 3, 4, 5, 6, 7, 8:
                return CGFloat(delta * 25);
            default:
                return 150;
            }
        }
    }
}
