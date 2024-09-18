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
        @Environment(ViewModel.self) private var viewModel
        
        var body: some View {
            @Bindable var viewModel = viewModel
            
            VStack(spacing: 0) {
                Header()
                
                GeometryReader { proxy in
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                QueueSection(tracks: viewModel.history, emptyText: "history.empty", defaultScrollAnchorAtBottom: true, onMove: nil, onDelete: {
                                    for index in $0 {
                                        AudioPlayer.current.removePlayed(at: index)
                                    }
                                }) { track, index in
                                    Row(track: track, draggable: false)
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            QueueNextButton {
                                                AudioPlayer.current.queue(track, after: 0, playbackInfo: .init(container: nil, queueLocation: .next))
                                            }
                                            .tint(.orange)
                                        }
                                        .swipeActions(edge: .leading) {
                                            QueueLaterButton(hideName: true) {
                                                AudioPlayer.current.queue(track, after: AudioPlayer.current.queue.count, playbackInfo: .init(container: nil, queueLocation: .later))
                                            }
                                            .tint(.blue)
                                        }
                                        .onTapGesture {
                                            AudioPlayer.current.restorePlayed(upTo: index)
                                        }
                                }
                                .id(QueueTab.history)
                                .frame(height: proxy.size.height)
                                
                                QueueSection(tracks: viewModel.queue, emptyText: "queue.empty", onMove: {
                                    for index in $0 {
                                        AudioPlayer.current.move(from: index, to: $1)
                                    }
                                }, onDelete: {
                                    for index in $0 {
                                        let _ = AudioPlayer.current.remove(at: index)
                                    }
                                }) { track, index in
                                    Row(track: track, draggable: true)
                                        .onTapGesture {
                                            AudioPlayer.current.skip(to: index)
                                        }
                                }
                                .id(QueueTab.queue)
                                .frame(height: proxy.size.height)
                                
                                if let infiniteQueue = viewModel.infiniteQueue {
                                    QueueSection(tracks: infiniteQueue, emptyText: "infiniteQueue.empty", onMove: nil, onDelete: {
                                        for index in $0 {
                                            let _ = AudioPlayer.current.remove(at: viewModel.queue.count + index)
                                        }
                                    }) { track, index in
                                        Row(track: track, draggable: false)
                                            .onTapGesture {
                                                AudioPlayer.current.skip(to: viewModel.queue.count + index)
                                            }
                                    }
                                    .id(QueueTab.infiniteQueue)
                                    .frame(height: proxy.size.height)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollIndicators(.hidden)
                        .scrollTargetBehavior(.paging)
                        .scrollPosition(id: $viewModel.queueTab, anchor: .top)
                        .mask(
                            VStack(spacing: 0) {
                                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                                    .frame(height: 32)
                                
                                Rectangle()
                                    .fill(Color.black)
                                
                                LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                                    .frame(height: 32)
                            }
                        )
                        .onChange(of: viewModel.currentTab, initial: true) {
                            scrollProxy.scrollTo(viewModel.queueTab, anchor: .top)
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: viewModel.queueTab)
        }
    }
}

private struct Header: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    private var title: LocalizedStringKey {
        switch viewModel.queueTab {
        case .history:
            "queue.history"
        case .infiniteQueue:
            "queue.infinite"
        default:
            "queue"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            LazyVStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Group {
                    if viewModel.queueTab != .infiniteQueue, let playbackInfo = viewModel.playbackInfo {
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
                    } else if viewModel.queueTab == .infiniteQueue {
                        Text("queue.infinite.text")
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
            }
            .contentTransition(.opacity)
            
            Spacer()
            
            if viewModel.queueTab == .queue {
                Group {
                    Button {
                        AudioPlayer.current.shuffled.toggle()
                    } label: {
                        Label("shuffle", systemImage: "shuffle")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(SymbolButtonStyle(active: viewModel.shuffled))
                    
                    Menu {
                        Section {
                            ForEach(RepeatMode.allCases.filter { AudioPlayer.current.infiniteQueue != nil || $0 != .infinite }) { repeatMode in
                                Toggle(isOn: .init(get: { viewModel.repeatMode == repeatMode }, set: { _ in AudioPlayer.current.repeatMode = repeatMode })) {
                                    switch repeatMode {
                                    case .none:
                                        Label("repeat.none", systemImage: "slash.circle")
                                    case .queue:
                                        Label("repeat.queue", systemImage: "repeat")
                                    case .track:
                                        Label("repeat.track", systemImage: "repeat.1")
                                    case .infinite:
                                        Label("repeat.infinite", systemImage: "infinity")
                                    }
                                }
                            }
                        }
                        
                        Section {
                            ForEach(NowPlaying.QueueTab.allCases) { tab in
                                Toggle(isOn: .init(get: { viewModel.queueTab == tab }, set: { _ in viewModel.queueTab = tab })) {
                                    switch tab {
                                    case .history:
                                        Text("queue.history")
                                    case .queue:
                                        Text("queue")
                                    case .infiniteQueue:
                                        Text("queue.infinite")
                                    }
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            Image(systemName: "repeat")
                                .hidden()
                            Image(systemName: "infinity")
                                .hidden()
                            
                            Label("repeat", systemImage: viewModel.repeatMode == .infinite ? "infinity" : "repeat\(viewModel.repeatMode == .track ? ".1" : "")")
                                .labelStyle(.iconOnly)
                        }
                    } primaryAction: {
                        AudioPlayer.current.repeatMode = viewModel.repeatMode.next
                    }
                    .id(viewModel.repeatMode)
                    .buttonStyle(SymbolButtonStyle(active: viewModel.repeatMode != .none))
                }
                .modifier(HoverEffectModifier(padding: 4))
                .transition(.opacity)
            } else if viewModel.queueTab == .infiniteQueue {
                Button {
                    if AudioPlayer.current.repeatMode == .infinite {
                        AudioPlayer.current.repeatMode = .none
                    } else {
                        AudioPlayer.current.repeatMode = .infinite
                    }
                } label: {
                    ZStack {
                        Image(systemName: "repeat")
                            .hidden()
                        
                        Label("queue.infinite", systemImage: "infinity")
                            .labelStyle(.iconOnly)
                    }
                }
                .buttonStyle(SymbolButtonStyle(active: viewModel.repeatMode == .infinite))
                .modifier(HoverEffectModifier(padding: 4))
                .id(viewModel.repeatMode)
                .transition(.opacity)
            }
        }
        .padding(.top, 16)
        .contentShape(.rect)
        .animation(.spring, value: viewModel.queueTab)
    }
}

private struct QueueSection<Content: View>: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let tracks: [Track]
    let emptyText: LocalizedStringKey
    var defaultScrollAnchorAtBottom = false
    
    let onMove: ((_ : IndexSet, _ : Int) -> Void)?
    let onDelete: (_ : IndexSet) -> Void
    
    @ViewBuilder let content: (_ track: Track, _ index: Int) -> Content
    
    @State private var position: String? = nil
    
    var body: some View {
        List {
            if tracks.isEmpty {
                HStack(spacing: 0) {
                    Spacer()
                    
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.top, 100)
                .padding(.horizontal, 20)
            }
            
            ForEach(Array(tracks.enumerated()), id: \.element) { index, track in
                content(track, index)
                    .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                    .contextMenu {
                        QueueButtons {
                            if $0 {
                                AudioPlayer.current.queue(track, after: 0, playbackInfo: .init(container: nil, queueLocation: .next))
                            } else {
                                AudioPlayer.current.queue(track, after: AudioPlayer.current.queue.count, playbackInfo: .init(container: nil, queueLocation: .later))
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            track.favorite.toggle()
                        } label: {
                            Label("favorite", systemImage: track.favorite ? "star.fill" : "star")
                        }
                        
                        Button {
                            viewModel.addToPlaylistTrack = track
                        } label: {
                            Label("playlist.add", systemImage: "plus")
                        }
                        .disabled(!JellyfinClient.shared.online)
                        
                        Divider()
                        
                        Button(action: { Navigation.navigate(albumId: track.album.id) }) {
                            Label("album.view", systemImage: "square.stack")
                            
                            if let albumName = track.album.name {
                                Text(albumName)
                            }
                        }
                        
                        ForEach(track.artists) { artist in
                            Button {
                                Navigation.navigate(artistId: artist.id)
                            } label: {
                                Label("artist.view", systemImage: "music.mic")
                                Text(artist.name)
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            AudioPlayer.current.removePlayed(at: index)
                        } label: {
                            Label("queue.remove", systemImage: "xmark")
                        }
                    } preview: {
                        TrackCollection.TrackPreview(track: track)
                    }
            }
            .onMove(perform: onMove)
            .onDelete(perform: onDelete)
        }
        .listStyle(.plain)
        .scrollPosition(id: $position)
        .scrollIndicators(.hidden)
        .contentMargins(.vertical, 8, for: .scrollContent)
        .task(id: viewModel.history) {
            if defaultScrollAnchorAtBottom {
                position = tracks.last?.id
            }
        }
    }
}

private struct Row: View {
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
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            Spacer(minLength: 12)
            
            if draggable {
                Label("queue.reorder", systemImage: "line.3.horizontal")
                    .bold()
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .id(track.id)
        .contentShape(.rect)
    }
}
