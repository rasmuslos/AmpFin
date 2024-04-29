//
//  NowPlayingView+Lyrics.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AFBase
import AFOffline
import AFPlayback

struct NowPlayingLyricsContainer: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Binding var controlsVisible: Bool
    
    @State private var failed = false
    @State private var lyrics: Track.Lyrics?
    @State private var activeLineIndex: Int = 0
    
    @State private var scrolling: Bool = false
    @State private var scrollTimeout: Task<(), Error>? = nil
    
    private var anchor: UnitPoint {
        horizontalSizeClass == .compact ? .top : .center
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                if let lyrics = lyrics {
                    LazyVStack {
                        ForEach(Array(lyrics.keys.sorted(by: <).enumerated()), id: \.offset) { index, key in
                            if index == activeLineIndex || lyrics[key]! != nil {
                                LyricLine(index: index, text: lyrics[key]!, activeLineIndex: activeLineIndex, scrolling: $scrolling)
                                    .onTapGesture {
                                        Task.detached {
                                            await AudioPlayer.current.seek(seconds: Array(lyrics.keys.sorted(by: <))[index])
                                            activeLineIndex = index
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 25)
                    .safeAreaPadding(.bottom, 175)
                } else {
                    Group {
                        if failed {
                            Text("lyrics.failed")
                                .font(.caption.smallCaps())
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        } else {
                            ProgressView()
                        }
                    }
                    .padding(.vertical, 50)
                    .frame(maxWidth: .infinity)
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
                if scrolling {
                    return
                }
                
                withAnimation(.spring) {
                    proxy.scrollTo(activeLineIndex, anchor: anchor)
                }
            }
            .onChange(of: scrolling) {
                if scrolling {
                    return
                }
                
                withAnimation(.spring) {
                    proxy.scrollTo(activeLineIndex, anchor: anchor)
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged({ gesture in
                        if 0 < gesture.translation.height {
                            controlsVisible = true
                        } else {
                            controlsVisible = false
                        }
                        
                        scrolling = true
                        
                        scrollTimeout?.cancel()
                        scrollTimeout = Task.detached { @Sendable in
                            try await Task.sleep(nanoseconds: UInt64(5 * NSEC_PER_SEC))
                            scrolling = false
                        }
                    })
            )
        }
        .onAppear(perform: fetchLyrics)
        .onChange(of: AudioPlayer.current.nowPlaying) {
            lyrics = nil
            activeLineIndex = 0
            fetchLyrics()
        }
        .onChange(of: AudioPlayer.current.currentTime) {
            updateLyricsIndex()
        }
    }
    
    // MARK: Helper
    
    private func updateLyricsIndex() {
        if let lyrics = lyrics, !lyrics.isEmpty {
            let currentTime = AudioPlayer.current.currentTime
            if let index = Array(lyrics.keys).sorted(by: <).lastIndex(where: { $0 <= currentTime }) {
                activeLineIndex = index
            } else {
                activeLineIndex = 0
            }
        } else {
            activeLineIndex = 0
        }
    }
    
    private func fetchLyrics() {
        if let trackId = AudioPlayer.current.nowPlaying?.id {
            failed = false
            
            Task.detached {
                if let lyrics = await OfflineManager.shared.getLyrics(trackId: trackId) {
                    self.lyrics = lyrics
                } else if let lyrics = try? await JellyfinClient.shared.getLyrics(trackId: trackId) {
                    self.lyrics = lyrics
                } else {
                    failed = true
                }
            }
        }
    }
}

// MARK: Line

extension NowPlayingLyricsContainer {
    struct LyricLine: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let index: Int
        let text: String?
        let activeLineIndex: Int
        
        @Binding var scrolling: Bool
        
        @State private var pulse: CGFloat = 1
        
        private var active: Bool {
            index == activeLineIndex
        }
        
        var body: some View {
            HStack {
                if let text = text {
                    Text(text)
                        .font(.system(size: horizontalSizeClass == .compact ? 33 : 50))
                    
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
            .blur(radius: active || scrolling ? 0 : 2)
            .tag(activeLineIndex)
            .animation(.spring, value: active)
            .animation(.easeInOut(duration: 0.3), value: activeLineIndex)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulse *= 1.2
                }
            }
            .padding(.vertical, horizontalSizeClass == .compact ? 10 : 25)
            .offset(y: 25 + determineAdditionalOffset())
        }
        
        private func determineAdditionalOffset() -> CGFloat {
            let delta = index - activeLineIndex
            return delta > 0 ? 15 : 0
        }
    }
}
