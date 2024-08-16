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
        
        @State private var dragging: (Int, Track)? = nil
        
        var body: some View {
            @Bindable var viewModel = viewModel
            
            VStack(spacing: 0) {
                Header(dragging: $dragging)
                
                GeometryReader { proxy in
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                QueueSection(tracks: viewModel.history, emptyText: "history.empty", defaultScrollAnchorAtBottom: true) { track, index in
                                    Row(track: track, draggable: false) {
                                        AudioPlayer.current.removePlayed(at: index)
                                    }
                                    .onTapGesture {
                                        AudioPlayer.current.restorePlayed(upTo: index)
                                    }
                                }
                                .id(QueueTab.history)
                                .frame(height: proxy.size.height)
                                
                                QueueSection(tracks: viewModel.queue, emptyText: "queue.empty") { track, index in
                                    Row(track: track, draggable: true) {
                                        let _ = AudioPlayer.current.remove(at: index)
                                    }
                                    .shadow(radius: dragging?.0 == index ? 8 : 0)
                                    .opacity(dragging?.0 == index ? 0.6 : 1)
                                    .animation(.spring, value: dragging?.0)
                                    .onDrag {
                                        dragging = (index, track)
                                        return TrackItemProvider() {
                                            dragging = nil
                                        }
                                    } preview: {
                                        TrackCollection.TrackPreview(track: track)
                                    }
                                    .onDrop(of: [.item], delegate: TrackDropDelegate(current: (index, track), dragging: $dragging))
                                    .onTapGesture {
                                        AudioPlayer.current.skip(to: index)
                                    }
                                }
                                .id(QueueTab.queue)
                                .frame(height: proxy.size.height)
                                
                                if let infiniteQueue = viewModel.infiniteQueue {
                                    QueueSection(tracks: infiniteQueue, emptyText: "infiniteQueue.empty") { track, index in
                                        Row(track: track, draggable: false) {
                                            let _ = AudioPlayer.current.remove(at: viewModel.queue.count + index)
                                        }
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
                        .scrollPosition(id: $viewModel.queueTab, anchor: .top)
                        .mask(
                            VStack(spacing: 0) {
                                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                                    .frame(height: 32)
                                
                                Rectangle()
                                    .fill(Color.black)
                                
                                LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0), Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                                    .frame(height: 32)
                            }
                        )
                        .onChange(of: viewModel.currentTab, initial: true) {
                            scrollProxy.scrollTo(viewModel.queueTab, anchor: .top)
                        }
                    }
                }
            }
            .sensoryFeedback(.levelChange, trigger: viewModel.queueTab)
        }
    }
}

private struct Header: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    @Binding var dragging: (Int, Track)?
    
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
                    if dragging != nil {
                        Text("queue.remove.dragging")
                    } else if viewModel.queueTab != .infiniteQueue, let playbackInfo = viewModel.playbackInfo {
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
                .foregroundStyle(.thinMaterial)
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
        .animation(.spring, value: dragging?.0)
        .animation(.spring, value: viewModel.queueTab)
        .onDrop(of: [.item], delegate: RemoveDropDelegate(dragging: $dragging))
    }
}

private struct QueueSection<Content: View>: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let tracks: [Track]
    let emptyText: LocalizedStringKey
    var defaultScrollAnchorAtBottom = false
    
    @State private var position: String? = nil
    
    @ViewBuilder let content: (_ track: Track, _ index: Int) -> Content
    
    var body: some View {
        ScrollView {
            if tracks.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(.regularMaterial)
                    .multilineTextAlignment(.center)
                    .padding(.top, 100)
                    .padding(.horizontal, 20)
            }
            
            ForEach(Array(tracks.enumerated()), id: \.element) {
                content($1, $0)
            }
        }
        .scrollPosition(id: $position)
        .scrollIndicators(.hidden)
        .contentMargins(.vertical, 16, for: .scrollContent)
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
    let remove: (() -> Void)
    
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
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Group {
                if removeVisible || !draggable {
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
            .foregroundStyle(.white.opacity(0.6))
        }
        .id(track.id)
        .contentShape(.rect)
    }
}

private class TrackItemProvider: NSItemProvider {
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
    var current: (Int, Track)
    var dragging: Binding<(Int, Track)?>
    
    func performDrop(info: DropInfo) -> Bool {
        dragging.wrappedValue = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard current.0 != dragging.wrappedValue?.0 && current.1 != dragging.wrappedValue?.1, let index = dragging.wrappedValue?.0 else {
            return
        }
        
        AudioPlayer.current.move(from: index, to: current.0)
        dragging.wrappedValue?.0 = current.0
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
private struct RemoveDropDelegate: DropDelegate {
    var dragging: Binding<(Int, Track)?>
    
    func performDrop(info: DropInfo) -> Bool {
        guard let index = dragging.wrappedValue?.0 else {
            return false
        }
        
        let _ = AudioPlayer.current.remove(at: index)
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
