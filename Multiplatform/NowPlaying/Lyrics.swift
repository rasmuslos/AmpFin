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
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if let lyrics = lyrics {
                        VStack(spacing: 0) {
                            ForEach(Array(lyrics.keys.sorted(by: <).enumerated()), id: \.offset) { index, key in
                                Line(index: index, text: lyrics[key]!, scrolling: scrolling, activeLineIndex: activeLineIndex)
                                    .onTapGesture {
                                        Task.detached {
                                            await AudioPlayer.current.seek(seconds: Array(lyrics.keys.sorted(by: <))[index])
                                            setActiveLineIndex(index)
                                        }
                                    }
                            }
                        }
                    } else {
                        Group {
                            if failed {
                                Text("lyrics.failed")
                                    .font(.caption.smallCaps())
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.outerSpacing)
                            } else {
                                ProgressView()
                            }
                        }
                        .padding(.vertical, 50)
                        .frame(maxWidth: .infinity)
                    }
                }
                .safeAreaPadding(.top, 45)
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
                            scrollTimeout = Task.detached { @Sendable in
                                try await Task.sleep(nanoseconds: UInt64(5 * NSEC_PER_SEC))
                                scrolling = false
                            }
                        })
                )
                .onAppear(perform: fetchLyrics)
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
                .onChange(of: AudioPlayer.current.nowPlaying) {
                    lyrics = nil
                    setActiveLineIndex(0)
                    fetchLyrics()
                }
                .onChange(of: AudioPlayer.current.currentTime) {
                    updateLyricsIndex()
                }
            }
        }
    }
}

private extension NowPlaying.Lyrics {
    func updateLyricsIndex() {
        if let lyrics = lyrics, !lyrics.isEmpty {
            let currentTime = AudioPlayer.current.currentTime
            if let index = Array(lyrics.keys).sorted(by: <).lastIndex(where: { $0 <= currentTime }) {
                setActiveLineIndex(index)
            } else {
                setActiveLineIndex(0)
            }
        } else {
            setActiveLineIndex(0)
        }
    }
    
    func fetchLyrics() {
        if let trackId = AudioPlayer.current.nowPlaying?.id {
            failed = false
            
            Task.detached {
                if let lyrics = await OfflineManager.shared.updateLyrics(trackId: trackId) {
                    self.lyrics = lyrics
                } else if let lyrics = await OfflineManager.shared.getLyrics(trackId: trackId) {
                    self.lyrics = lyrics
                } else {
                    failed = true
                }
            }
        }
    }
    
    func setActiveLineIndex(_ index: Int) {
        withAnimation(.spring) {
            activeLineIndex = index
        }
    }
}

// MARK: Line

private extension NowPlaying {
    struct Line: View {
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
            horizontalSizeClass == .compact ? 15 : 30
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
                    }
                }
                
                Spacer()
            }
            .fontWeight(.heavy)
            .foregroundStyle(active ? .white.opacity(0.9) : .gray.opacity(0.4))
            .blur(radius: active || scrolling ? 0 : 2)
            .padding(.vertical, active || text != nil ? padding : 0)
            .task {
                pulse = 1
                
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulse = 1.2
                }
            }
        }
    }
}
