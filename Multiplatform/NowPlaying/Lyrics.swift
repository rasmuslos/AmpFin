//
//  NowPlayingView+Lyrics.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

extension NowPlaying {
    struct Lyrics: View {
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
        
        private var lyricsKeys: [Double]? {
            guard let lyrics else {
                return nil
            }
            
            return Array(lyrics.keys).sorted(by: <)
        }
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if let lyrics, let lyricsKeys {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(lyricsKeys.enumerated()), id: \.offset) { index, key in
                                Line(index: index, text: lyrics[key]!, scrolling: scrolling, activeLineIndex: activeLineIndex)
                                    .onTapGesture {
                                        AudioPlayer.current.currentTime = lyricsKeys[index]
                                        setActiveLineIndex(index)
                                    }
                            }
                        }
                    } else {
                        Group {
                            if failed {
                                Text("lyrics.failed")
                                    .font(.caption.smallCaps())
                                    .foregroundStyle(.regularMaterial)
                                    .multilineTextAlignment(.center)
                                    .padding(20)
                            } else {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    }
                }
                .safeAreaPadding(.top, 44)
                .safeAreaPadding(.bottom, 100)
                .mask(
                    VStack(spacing: 0) {
                        LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                            .frame(height: 60)
                        
                        Rectangle()
                            .fill(Color.black)
                        
                        LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                            .frame(height: 60)
                    }
                )
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
                            scrollTimeout = Task.detached {
                                try await Task.sleep(nanoseconds: UInt64(5) * NSEC_PER_SEC)
                                try Task.checkCancellation()
                                
                                scrolling = false
                            }
                        })
                )
                .onDisappear {
                    scrollTimeout?.cancel()
                }
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
                .onChange(of: AudioPlayer.current.currentTime) {
                    updateLyricsIndex()
                }
                .task(id: AudioPlayer.current.nowPlaying) {
                    lyrics = nil
                    await fetchLyrics()
                    
                    setActiveLineIndex(0)
                    updateLyricsIndex()
                }
            }
        }
    }
}

private extension NowPlaying.Lyrics {
    func updateLyricsIndex() {
        guard let lyricsKeys = lyricsKeys, !lyricsKeys.isEmpty else {
            setActiveLineIndex(0)
            return
        }
        
        let currentTime = AudioPlayer.current.currentTime
        if let index = lyricsKeys.lastIndex(where: { $0 <= currentTime }) {
            setActiveLineIndex(index)
        } else {
            setActiveLineIndex(0)
        }
    }
    
    func fetchLyrics() async {
        guard let trackId = AudioPlayer.current.nowPlaying?.id else {
            failed = true
            return
        }
        
        failed = false
        
        if let lyrics = try? await OfflineManager.shared.lyrics(trackId: trackId, allowUpdate: true) {
            self.lyrics = lyrics
        } else if let lyrics = try? await JellyfinClient.shared.lyrics(trackId: trackId) {
            self.lyrics = lyrics
        } else {
            failed = true
        }
    }
    
    func setActiveLineIndex(_ index: Int) {
        withAnimation(.spring) {
            activeLineIndex = index
        }
    }
}

// MARK: Line


private struct Line: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let index: Int
    let text: String?
    var scrolling: Bool
    let activeLineIndex: Int
    
    @State private var pulse: CGFloat = .zero
    
    private var active: Bool {
        index == activeLineIndex
    }
    private var padding: CGFloat {
        horizontalSizeClass == .compact ? 16 : 32
    }
    
    var body: some View {
        HStack {
            if let text = text {
                Text(text)
                    .font(.system(size: horizontalSizeClass == .compact ? 33 : 50))
            } else {
                if index == activeLineIndex {
                    HStack(spacing: 10) {
                        ForEach(1...3, id: \.hashValue) { _ in
                            Circle()
                                .frame(width: 15 * pulse)
                        }
                    }
                    .frame(height: 20)
                    .task {
                        pulse = 1
                        
                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                            pulse = 1.2
                        }
                    }
                }
            }
            
            Spacer()
        }
        .fontWeight(.heavy)
        .foregroundStyle(active ? .ultraThickMaterial : .ultraThinMaterial)
        .blur(radius: active || scrolling ? 0 : 2)
        .opacity(active || scrolling ? 1 : 0.4)
        .padding(.vertical, active || text != nil ? padding : 0)
    }
}
