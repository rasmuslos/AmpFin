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
        @Binding var controlsVisible: Bool
        
        @State var lyrics: Track.Lyrics?
        @State var activeLineIndex: Int = 0
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if let lyrics = lyrics {
                        LazyVStack {
                            ForEach(Array(lyrics.keys.sorted(by: <).enumerated()), id: \.offset) { index, key in
                                if index == activeLineIndex || lyrics[key]! != nil {
                                    LyricLine(index: index, text: lyrics[key]!, activeLineIndex: $activeLineIndex)
                                        .onTapGesture {
                                            Task.detached {
                                                await AudioPlayer.shared.seek(seconds: Array(lyrics.keys.sorted(by: <))[index])
                                                activeLineIndex = index
                                            }
                                        }
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
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.trackChange), perform: { _ in
                lyrics = nil
                activeLineIndex = 0
                fetchLyrics()
            })
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.positionUpdated), perform: { _ in
                updateLyricsIndex()
            })
        }
        
        // MARK: Helper
        
        func updateLyricsIndex() {
            if let lyrics = lyrics, !lyrics.isEmpty {
                let currentTime = AudioPlayer.shared.currentTime()
                if let index = Array(lyrics.keys).sorted(by: <).lastIndex(where: { $0 <= currentTime }) {
                    activeLineIndex = index
                } else {
                    activeLineIndex = 0
                }
            } else {
                activeLineIndex = 0
            }
        }
        
        func fetchLyrics() {
            if let trackId = AudioPlayer.shared.nowPlaying?.id {
                Task.detached {
                    if let offlineLyrics = await OfflineManager.shared.getLyrics(trackId: trackId) {
                        self.lyrics = offlineLyrics.lyrics
                    } else if let lyrics = try? await JellyfinClient.shared.getLyrics(trackId: trackId) {
                        self.lyrics = lyrics
                    }
                 
                }
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
                } else {
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
            .animation(.easeInOut(duration: 0.3).delay(active ? 0.25 : Double(index - activeLineIndex) / 7), value: activeLineIndex)
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
