//
//  NowPlayingSheet+Queue.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

// MARK: Container

extension NowPlayingSheet {
    struct Queue: View {
        let item: SongItem
        let namespace: Namespace.ID
        
        @State var histroy = AudioPlayer.shared.history
        @State var queue = AudioPlayer.shared.queue
        
        @State var nowPlaying = AudioPlayer.shared.nowPlaying!
        @State var shuffled = AudioPlayer.shared.shuffled
        
        @State var showHistory = false
        
        var body: some View {
            HStack {
                Text(showHistory ? "History" : "Queue")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    AudioPlayer.shared.shuffle(!shuffled)
                } label: {
                    Image(systemName: "shuffle")
                        .foregroundStyle(shuffled ? Color.accentColor : .secondary)
                }
                .padding()
                
                Button {
                    showHistory.toggle()
                } label: {
                    Image(systemName: "calendar.day.timeline.leading")
                        .foregroundStyle(showHistory ? Color.accentColor : .secondary)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 5)
            
            List {
                if showHistory {
                    ForEach(Array(histroy.enumerated()), id: \.offset) { index, item in
                        QueueItem(item: item)
                            .onTapGesture {
                                AudioPlayer.shared.restoreHistory(index: index)
                            }
                    }
                    .defaultScrollAnchor(.bottom)
                } else {
                    ForEach(Array(queue.enumerated()), id: \.offset) { index, item in
                        QueueItem(item: item)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let _ = AudioPlayer.shared.removeItem(index: index)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                            .onTapGesture {
                                AudioPlayer.shared.skip(to: index)
                            }
                    }
                    .onMove { from, to in
                        from.forEach {
                            AudioPlayer.shared.moveItem(from: $0, to: to)
                        }
                    }
                    .defaultScrollAnchor(.top)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            // move drag indicator
            .padding(.trailing, -20)
            
            // .environment(\.editMode, .constant(.active))
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                        .frame(height: 40)
                    
                    Rectangle().fill(Color.black)
                    
                    LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                        .frame(height: 40)
                }
            )
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.ItemChange), perform: { _ in
                withAnimation {
                    nowPlaying = AudioPlayer.shared.nowPlaying!
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.QueueUpdated), perform: { _ in
                withAnimation {
                    histroy = AudioPlayer.shared.history
                    queue = AudioPlayer.shared.queue
                    
                    shuffled = AudioPlayer.shared.shuffled
                }
            })
        }
    }
}

// MARK: Item

extension NowPlayingSheet {
    struct QueueItem: View {
        let item: SongItem
        
        var body: some View {
            HStack {
                ItemImage(cover: item.cover)
                    .frame(width: 45)
                
                VStack(alignment: .leading) {
                    Text(item.name)
                        .lineLimit(1)
                        .font(.headline)
                    
                    Text(item.artists.map { $0.name }.joined(separator: ", "))
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                
                Spacer()
            }
            .listRowInsets(.init(top: 5, leading: 0, bottom: 5, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
}
