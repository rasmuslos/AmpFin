//
//  NowPlayingView+Lyrics.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    struct Lyrics: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(ViewModel.self) private var viewModel
        
        @State private var lyricsViewModel: LyricsViewModel
        
        init(track: Track) {
            _lyricsViewModel = .init(initialValue: .init(track: track))
        }
        
        private var anchor: UnitPoint {
            horizontalSizeClass == .compact ? .top : .center
        }
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if lyricsViewModel.loaded {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(lyricsViewModel.lyricsKeys.enumerated()), id: \.offset) { index, key in
                                Line(index: index)
                            }
                        }
                        .padding(.horizontal, 28)
                    } else {
                        Group {
                            if lyricsViewModel.failed {
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
                .padding(.horizontal, -28)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged({ gesture in lyricsViewModel.didScroll(up: 0 < gesture.velocity.height) })
                )
                .environment(lyricsViewModel)
                .onChange(of: lyricsViewModel.activeLineIndex) {
                    lyricsViewModel.scroll(proxy, anchor: anchor)
                }
                .onChange(of: lyricsViewModel.scrolling) {
                    lyricsViewModel.scroll(proxy, anchor: anchor)
                }
                .onChange(of: lyricsViewModel.controlsVisible) {
                    withAnimation {
                        if viewModel.currentTab == .lyrics {
                            viewModel.controlsVisible = lyricsViewModel.controlsVisible
                        }
                    }
                }
                .onChange(of: AudioPlayer.current.currentTime) {
                    lyricsViewModel.updateLyricsIndex()
                }
                .task(id: AudioPlayer.current.nowPlaying) {
                    await lyricsViewModel.trackDidChange()
                    lyricsViewModel.scroll(proxy, anchor: anchor)
                }
            }
        }
    }
}

private struct Line: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(LyricsViewModel.self) private var lyricsViewModel
    
    let index: Int
    
    @State private var pulse: CGFloat = .zero
    
    private var active: Bool {
        index == lyricsViewModel.activeLineIndex
    }
    private var delta: CGFloat {
        CGFloat(index - lyricsViewModel.activeLineIndex)
    }
    
    // this is cursed
    private var text: String? {
        lyricsViewModel.lyrics[lyricsViewModel.lyricsKeys[index]] ?? nil
    }
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    private var padding: CGFloat {
        horizontalSizeClass == .compact ? 16 : 32
    }
    
    var body: some View {
        HStack {
            if let text = text {
                Button {
                    AudioPlayer.current.currentTime = lyricsViewModel.lyricsKeys[index]
                    lyricsViewModel.setActiveLine(index)
                } label: {
                    Text(text)
                        .font(isCompact ? .largeTitle : .system(size: 50))
                }
                .buttonStyle(.plain)
            } else {
                if index == lyricsViewModel.activeLineIndex {
                    let duration = index == lyricsViewModel.lyrics.count - 1 ? AudioPlayer.current.duration : lyricsViewModel.lyricsKeys[index + 1]
                    let done = duration - AudioPlayer.current.currentTime
                    let percentage = 1 - done / duration
                    
                    HStack(spacing: 10) {
                        ForEach(1...3, id: \.hashValue) { i in
                            let dotOffset = 0.33 * Double(i - 1)
                            let visible = min(1, max(0, percentage - dotOffset) * 3)
                            
                            Circle()
                                .frame(width: 15 * pulse)
                                .opacity(0.2 + 0.8 * visible)
                                .animation(.linear, value: visible)
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
        .bold()
        .foregroundStyle(active ? .white.opacity(0.8) : .gray.opacity(0.4))
        .blur(radius: active || lyricsViewModel.scrolling ? 0 : min(4, abs(delta) * 0.75 + 1.25))
        .padding(.vertical, active || text != nil ? padding : 0)
    }
}

@Observable
private class LyricsViewModel {
    let track: Track
    
    var failed: Bool
    var lyrics: Track.Lyrics
    
    var activeLineIndex: Int
    
    var scrolling: Bool
    var controlsVisible: Bool
    
    var scrollTimeout: Task<Void, Error>?
    
    init(track: Track) {
        self.track = track
        
        failed = false
        lyrics = [:]
        
        activeLineIndex = 0
        
        scrolling = true
        controlsVisible = true
        
        scrollTimeout = nil
        startScrollTimer()
    }
}
private extension LyricsViewModel {
    func startScrollTimer() {
        scrollTimeout?.cancel()
        scrollTimeout = Task {
            try await Task.sleep(nanoseconds: UInt64(4) * NSEC_PER_SEC)
            try Task.checkCancellation()
            
            scrolling = false
            controlsVisible = false
        }
    }
    func didScroll(up: Bool) {
        withAnimation {
            scrolling = true
            controlsVisible = up
        }
        
        startScrollTimer()
    }
    
    func scroll(_ proxy: ScrollViewProxy, anchor: UnitPoint) {
        if scrolling {
            return
        }
        
        withAnimation(.spring) {
            proxy.scrollTo(activeLineIndex, anchor: anchor)
        }
    }
    
    func trackDidChange() async {
        lyrics = [:]
        setActiveLine(0)
        
        // TODO: scroll to top when iOS 18 releases (what a stupid thing to write)
        
        guard let trackId = AudioPlayer.current.nowPlaying?.id else {
            failed = true
            return
        }
        
        failed = false
        
        if let lyrics = try? OfflineManager.shared.lyrics(trackId: trackId, allowUpdate: true) {
            self.lyrics = lyrics
        } else if let lyrics = try? await JellyfinClient.shared.lyrics(trackId: trackId) {
            self.lyrics = lyrics
        } else {
            failed = true
        }
        
        updateLyricsIndex()
    }
    
    func updateLyricsIndex() {
        guard !lyricsKeys.isEmpty else {
            setActiveLine(0)
            return
        }
        
        let currentTime = AudioPlayer.current.currentTime
        
        if let index = lyricsKeys.lastIndex(where: { $0 <= currentTime }) {
            setActiveLine(index)
        } else {
            setActiveLine(0)
        }
    }
    func setActiveLine(_ index: Int) {
        withAnimation(.spring) {
            activeLineIndex = index
        }
    }
}
private extension LyricsViewModel {
    var lyricsKeys: [Double] {
        Array(lyrics.keys).sorted(by: <)
    }
    
    var loaded: Bool {
        !lyrics.isEmpty && !lyricsKeys.isEmpty
    }
}
