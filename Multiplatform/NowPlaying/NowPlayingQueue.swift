//
//  NowPlayingView+Queue.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import TipKit
import AFBase
import AFPlayback

// MARK: Container

struct NowPlayingQueue: View {
    @State private var showHistory = false
    
    var body: some View {
        HStack {
            Text(showHistory ? "queue.history" : "queue.queue")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Button {
                if AudioPlayer.current.repeatMode == .none {
                    AudioPlayer.current.repeatMode = .queue
                } else if AudioPlayer.current.repeatMode == .queue {
                    AudioPlayer.current.repeatMode = .track
                } else if AudioPlayer.current.repeatMode == .track {
                    AudioPlayer.current.repeatMode = .none
                }
            } label: {
                if AudioPlayer.current.repeatMode == .track {
                    Image(systemName: "repeat.1")
                } else if AudioPlayer.current.repeatMode == .none || AudioPlayer.current.repeatMode == .queue {
                    Image(systemName: "repeat")
                }
            }
            .id(AudioPlayer.current.repeatMode)
            .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none))
            .padding(.horizontal, 4)
            
            Button {
                AudioPlayer.current.shuffled = !AudioPlayer.current.shuffled
            } label: {
                Image(systemName: "shuffle")
            }
            .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.shuffled))
            .padding(.horizontal, 4)
            
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showHistory.toggle()
                }
            } label: {
                Image(systemName: "calendar.day.timeline.leading")
            }
            .buttonStyle(SymbolButtonStyle(active: showHistory))
        }
        .padding(.top, 10)
        .padding(.bottom, -10)
        
        List {
            if showHistory {
                ForEach(Array(AudioPlayer.current.history.enumerated()), id: \.offset) { index, track in
                    QueueTrackRow(track: track, draggable: false)
                        .padding(.top, index == 0 ? 15 : 0)
                        .padding(.bottom, (index == AudioPlayer.current.history.count - 1) ? 15 : 0)
                        .onTapGesture {
                            AudioPlayer.current.restoreHistory(index: index)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                AudioPlayer.current.queueTrack(track, index: 0)
                                AudioPlayer.current.removeHistoryTrack(index: index)
                            } label: {
                                Label("queue.next", systemImage: "text.line.first.and.arrowtriangle.forward")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                AudioPlayer.current.queueTrack(track, index: AudioPlayer.current.queue.count)
                                AudioPlayer.current.removeHistoryTrack(index: index)
                            } label: {
                                Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
                            }
                            .tint(.blue)
                        }
                }
                .defaultScrollAnchor(.bottom)
            } else {
                TipView(HistoryTip())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .foregroundStyle(.black)
                    .padding(.top, 20)
                
                ForEach(Array(AudioPlayer.current.queue.enumerated()), id: \.offset) { index, track in
                    QueueTrackRow(track: track, draggable: true)
                        .id(UUID())
                        .onTapGesture {
                            AudioPlayer.current.skip(to: index)
                        }
                        .padding(.top, index == 0 ? 15 : 0)
                        .padding(.bottom, (index == AudioPlayer.current.queue.count - 1) ? 15 : 0)
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
        .padding(.horizontal, -30)
        // this is required because SwiftUI sucks ass
        .mask(
            VStack(spacing: 0) {
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 40)
                
                Rectangle().fill(Color.black)
                
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 40)
            }
        )
    }
}

// MARK: Item

extension NowPlayingQueue {
    struct QueueTrackRow: View {
        let track: Track
        let draggable: Bool
        
        var body: some View {
            HStack {
                ItemImage(cover: track.cover)
                    .frame(width: 50)
                
                VStack(alignment: .leading) {
                    Text(track.name)
                        .lineLimit(1)
                        .font(.body)
                    
                    if let artistName = track.artistName {
                        Text(artistName)
                            .lineLimit(1)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                
                Spacer()
                
                if draggable {
                    Image(systemName: "line.3.horizontal")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 5, leading: 30, bottom: 5, trailing: 30))
        }
    }
}
