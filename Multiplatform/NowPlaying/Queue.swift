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
        
        @State private var dragging: Int? = nil
        @State private var scrollPosition: QueueTab? = .queue
        
        var body: some View {
            VStack {
                Header(scrollPosition: scrollPosition ?? .queue, dragging: $dragging)
                
                GeometryReader { proxy in
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                QueueSection(tracks: viewModel.history, defaultScrollAnchorAtBottom: true) { track, index in
                                    Row(track: track) {
                                        AudioPlayer.current.removePlayed(at: index)
                                    }
                                    .onTapGesture {
                                        AudioPlayer.current.restorePlayed(upTo: index)
                                    }
                                }
                                .id(QueueTab.history)
                                .frame(height: proxy.size.height)
                                
                                QueueSection(tracks: viewModel.queue) { track, index in
                                    Row(track: track) {
                                        let _ = AudioPlayer.current.remove(at: index)
                                    }
                                    .onDrag {
                                        dragging = index
                                        return TrackItemProvider() {
                                            dragging = nil
                                        }
                                    }
                                    .onDrop(of: [.item], delegate: TrackDropDelegate(current: index, dragging: $dragging))
                                    .onTapGesture {
                                        AudioPlayer.current.skip(to: index)
                                    }
                                }
                                .id(QueueTab.queue)
                                .frame(height: proxy.size.height)
                                
                                if let infiniteQueue = viewModel.infiniteQueue {
                                    QueueSection(tracks: infiniteQueue) { track, index in
                                        Row(track: track, remove: nil)
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
                        .scrollDisabled(dragging != nil)
                        .scrollPosition(id: $scrollPosition, anchor: .top)
                        .mask(
                            VStack(spacing: 0) {
                                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                                    .frame(height: 20)
                                
                                Rectangle()
                                    .fill(Color.black)
                                
                                LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                                    .frame(height: 20)
                            }
                        )
                        .onAppear {
                            scrollProxy.scrollTo(scrollPosition, anchor: .top)
                        }
                    }
                }
            }
        }
    }
}

private struct Header: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let scrollPosition: QueueTab
    @Binding var dragging: Int?
    
    private var title: LocalizedStringKey {
        switch scrollPosition {
            case .history:
                "queue.history"
            case .queue:
                "queue"
            case .infiniteQueue:
                "queue.infinite"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Group {
                    if dragging != nil {
                        Text("queue.remove.dragging")
                    } else if scrollPosition != .infiniteQueue, let playbackInfo = viewModel.playbackInfo {
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
                    } else if scrollPosition == .infiniteQueue {
                        Text("queue.infinite.text")
                    }
                }
                .font(.caption)
                .foregroundStyle(.thinMaterial)
                .lineLimit(1)
            }
            .contentTransition(.opacity)
            
            Spacer()
            
            if scrollPosition == .queue {
                Group {
                    Button {
                        AudioPlayer.current.shuffled.toggle()
                    } label: {
                        Label("shuffle", systemImage: "shuffle")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(SymbolButtonStyle(active: viewModel.shuffled))
                    
                    Button {
                        AudioPlayer.current.repeatMode = viewModel.repeatMode.next
                    } label: {
                        ZStack {
                            Image(systemName: "repeat")
                                .hidden()
                            Image(systemName: "infinity")
                                .hidden()
                            
                            Label("repeat", systemImage: viewModel.repeatMode == .infinite ? "infinity" : "repeat\(viewModel.repeatMode == .track ? ".1" : "")")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .id(viewModel.repeatMode)
                    .buttonStyle(SymbolButtonStyle(active: viewModel.repeatMode != .none))
                }
                .modifier(HoverEffectModifier(padding: 4))
                .transition(.opacity)
            } else if scrollPosition == .infiniteQueue {
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
        .animation(.spring, value: dragging)
        .animation(.spring, value: scrollPosition)
        .onDrop(of: [.item], delegate: RemoveDropDelegate(dragging: $dragging))
    }
}

private struct QueueSection<Content: View>: View {
    let tracks: [Track]
    var defaultScrollAnchorAtBottom = false
    
    @State private var position: String? = nil
    
    @ViewBuilder let content: (_ track: Track, _ index: Int) -> Content
    
    var body: some View {
        ScrollView {
            if tracks.isEmpty {
                Text("queue.empty")
                    .font(.caption.smallCaps())
                    .foregroundStyle(.regularMaterial)
                    .multilineTextAlignment(.center)
                    .padding(20)
            }
            
            ForEach(Array(tracks.enumerated()), id: \.element) {
                content($1, $0)
            }
        }
        .scrollPosition(id: $position)
        .scrollIndicators(.hidden)
        .contentMargins(.top, 12, for: .scrollContent)
        .defaultScrollAnchor(defaultScrollAnchorAtBottom && !tracks.isEmpty ? .bottom : .top)
    }
}

private struct Row: View {
    let track: Track
    let remove: (() -> Void)?
    
    @State private var removeVisible = false
    
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
            
            Group {
                if removeVisible, let remove = remove {
                    Button {
                        remove()
                    } label: {
                        ZStack {
                            Image(systemName: "line.3.horizontal")
                                .hidden()
                            
                            Label("queue.remove", systemImage: "xmark")
                        }
                    }
                } else {
                    Button {
                        withAnimation {
                            removeVisible = true
                        }
                    } label: {
                        Label("queue.reorder", systemImage: "line.3.horizontal")
                    }
                }
            }
            .bold()
            .fontDesign(.rounded)
            .labelStyle(.iconOnly)
            .foregroundStyle(.thinMaterial)
        }
        .id(track.id)
        .contentShape(.rect)
    }
}

class TrackItemProvider: NSItemProvider {
    var didEnd: () -> Void
    
    init(didEnd: @escaping () -> Void) {
        self.didEnd = didEnd
        super.init()
    }
    
    deinit {
        didEnd()
    }
}
private struct TrackDropDelegate: DropDelegate {
    var current: Int
    var dragging: Binding<Int?>
    
    func performDrop(info: DropInfo) -> Bool {
        dragging.wrappedValue = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let index = dragging.wrappedValue else {
            return
        }
        
        if current != index {
            if AudioPlayer.current.queue[current].id != AudioPlayer.current.queue[index].id {
                withAnimation {
                    AudioPlayer.current.move(from: index, to: current)
                }
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
private struct RemoveDropDelegate: DropDelegate {
    var dragging: Binding<Int?>
    
    func performDrop(info: DropInfo) -> Bool {
        guard let index = dragging.wrappedValue else {
            return false
        }
        
        let _ = AudioPlayer.current.remove(at: index)
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

private enum QueueTab: Hashable, Identifiable, Equatable {
    case history
    case queue
    case infiniteQueue
    
    var id: Self {
        self
    }
}
