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
        
        private var anchor: UnitPoint {
            horizontalSizeClass == .compact ? .top : .center
        }
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if viewModel.lyricsLoaded {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.lyricsKeys.enumerated()), id: \.offset) { index, key in
                                Line(index: index)
                            }
                        }
                        .padding(.horizontal, 28)
                    } else {
                        Group {
                            if viewModel.lyricsFetchFailed {
                                Text("lyrics.failed")
                                    .font(.subheadline)
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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.tapGestureFiredNotification)) { _ in
                    viewModel.didInteract()
                }
                .onChange(of: viewModel.activeLineIndex, initial: true) {
                    viewModel.scroll(proxy, anchor: anchor)
                }
                .onChange(of: viewModel.scrolling) {
                    viewModel.scroll(proxy, anchor: anchor)
                }
            }
        }
    }
}

private struct Line: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let index: Int
    
    @State private var pulse: CGFloat = .zero
    
    private var active: Bool {
        index == viewModel.activeLineIndex
    }
    private var delta: CGFloat {
        CGFloat(index - viewModel.activeLineIndex)
    }
    
    // this is cursed
    private var text: String? {
        if index < viewModel.lyricsKeys.count, let text = viewModel.lyrics[viewModel.lyricsKeys[index]] {
            return text
        }
        
        return nil
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
                    AudioPlayer.current.currentTime = viewModel.lyricsKeys[index]
                    viewModel.setActiveLine(index)
                } label: {
                    Text(text)
                        .font(isCompact ? .largeTitle : .system(size: 50))
                }
                .buttonStyle(.plain)
            } else {
                if index == viewModel.activeLineIndex {
                    let duration = index + 1 >= viewModel.lyrics.count ? viewModel.duration : viewModel.lyricsKeys[index + 1]
                    let done = duration - viewModel.currentTime
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
        .blur(radius: active || viewModel.scrolling ? 0 : min(4, abs(delta) * 0.75 + 1.25))
        .padding(.vertical, active || text != nil ? padding : 0)
    }
}

