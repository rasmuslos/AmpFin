//
//  NowPlayingView+Queue.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import TipKit
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    struct Queue: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        @State private var showHistory = false
        
        var body: some View {
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(showHistory ? "queue.history" : "queue")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let playbackInfo = AudioPlayer.current.playbackInfo {
                        Group {
                            if let container = playbackInfo.container {
                                if container.type == .album {
                                    Text("playback.album \(container.name)")
                                } else if container.type == .playlist {
                                    Text("playback.playlist \(container.name)")
                                } else if container.type == .artist {
                                    Text("playback.artist \(container.name)")
                                }
                            } else if let search = playbackInfo.search, !search.isEmpty {
                                Text("playback.search \(search)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.thinMaterial)
                        .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Group {
                    Button {
                        AudioPlayer.current.shuffled.toggle()
                    } label: {
                        Label("shuffle", systemImage: "shuffle")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.shuffled))
                    
                    Button {
                        if AudioPlayer.current.repeatMode == .none {
                            AudioPlayer.current.repeatMode = .queue
                        } else if AudioPlayer.current.repeatMode == .queue {
                            AudioPlayer.current.repeatMode = .track
                        } else if AudioPlayer.current.repeatMode == .track {
                            AudioPlayer.current.repeatMode = .none
                        }
                    } label: {
                        Label("repeat", systemImage: "repeat\(AudioPlayer.current.repeatMode == .track ? ".1" : "")")
                            .labelStyle(.iconOnly)
                    }
                    .id(AudioPlayer.current.repeatMode)
                    .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none))
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showHistory.toggle()
                        }
                    } label: {
                        Label("history", systemImage: "calendar.day.timeline.leading")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(SymbolButtonStyle(active: showHistory))
                }
                .modifier(HoverEffectModifier(padding: 4))
            }
            .padding(.top, 16)
            .padding(.bottom, -10)
            
            List {
                if showHistory {
                    ForEach(Array(AudioPlayer.current.history.enumerated()), id: \.offset) { index, track in
                        Row(track: track, draggable: false)
                            .onTapGesture {
                                AudioPlayer.current.restoreHistory(index: index)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                QueueNextButton {
                                    AudioPlayer.current.queueTrack(track, index: 0, playbackInfo: .init(container: nil, queueLocation: .next))
                                    AudioPlayer.current.removeHistoryTrack(index: index)
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading) {
                                QueueLaterButton(hideName: true) {
                                    AudioPlayer.current.queueTrack(track, index: AudioPlayer.current.queue.count, playbackInfo: .init(container: nil, queueLocation: .later))
                                    AudioPlayer.current.removeHistoryTrack(index: index)
                                }
                                .tint(.blue)
                            }
                    }
                } else {
                    TipView(HistoryTip())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 20, leading: 0, bottom: 12, trailing: 0))
                    
                    ForEach(Array(AudioPlayer.current.queue.enumerated()), id: \.offset) { index, track in
                        Row(track: track, draggable: true)
                            .id(UUID())
                            .onTapGesture {
                                AudioPlayer.current.skip(to: index)
                            }
                    }
                    .onMove { from, to in
                        from.forEach {
                            AudioPlayer.current.moveTrack(from: $0, to: to)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach {
                            let _ = AudioPlayer.current.removeTrack(index: $0)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(showHistory ? .bottom : .top)
            .safeAreaPadding(.vertical, 15)
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                        .frame(height: 40)
                    
                    Rectangle()
                        .fill(Color.black)
                    
                    LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                        .frame(height: 40)
                }
            )
        }
    }
}

private extension NowPlaying {
    struct Row: View {
        let track: Track
        let draggable: Bool
        
        var body: some View {
            HStack(spacing: 0) {
                ItemImage(cover: track.cover)
                    .frame(width: 48)
                    .padding(.trailing, 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                        .lineLimit(1)
                        .font(.body)
                    
                    if let artistName = track.artistName {
                        Text(artistName)
                            .lineLimit(1)
                            .font(.callout)
                            .foregroundStyle(.thinMaterial)
                    }
                }
                
                Spacer()
                
                if draggable {
                    Label("queue.reorder", systemImage: "line.3.horizontal")
                        .labelStyle(.iconOnly)
                        .imageScale(.large)
                        .foregroundStyle(.thinMaterial)
                        .padding(.leading, 16)
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
            .contentShape(.hoverMenuInteraction, .rect)
        }
    }
}
