//
//  TrackList.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase
import AFPlayback

struct TrackList: View {
    let tracks: [Track]
    let container: Item?
    
    var deleteCallback: DeleteCallback = nil
    var moveCallback: MoveCallback = nil
    
    var count = 0
    var loadMore: LoadCallback = nil
    
    @State private var working = false
    
    private var disks: [Int] {
        tracks.reduce([Int]()) {
            if !$0.contains($1.index.disk) {
                return $0 + [$1.index.disk]
            }
            
            return $0
        }
    }
    
    private var album: Album? {
        container as? Album
    }
    private var useDiskSections: Bool {
        album != nil && disks.count > 1
    }
    
    var body: some View {
        if useDiskSections {
            ForEach(disks.sorted(), id: \.hashValue) { disk in
                Section {
                    TrackSection(tracks: sort(tracks: tracks.filter{ $0.index.disk == disk }), album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, moveCallback: moveCallback, expand: expand)
                } header: {
                    Text("tracks.disk \(disk)")
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .padding(.top, -25)
            }
        } else {
            TrackSection(tracks: sort(tracks: tracks), album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, moveCallback: moveCallback, expand: expand)
        }
        
        ForEach(0..<(min(10000, max(0, count - tracks.count))), id: \.hashValue) { _ in
            TrackListRow.placeholder
                .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
                .onAppear { expand() }
        }
    }
}

extension TrackList {
    struct TrackSection: View {
        let tracks: [Track]
        let album: Album?
        
        let startPlayback: (Track) -> ()
        let deleteCallback: DeleteCallback
        let moveCallback: MoveCallback
        let expand: Expand
        
        var body: some View {
            if let moveCallback = moveCallback {
                ForEach(tracks) { track in
                    ModifiedTrackListRow(track: track, album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, expand: track == tracks.last ? expand : nil)
                }
                .onDelete(perform: { _ in })
                .onMove(perform: { from, to in
                    from.map { tracks[$0] }.forEach {
                        moveCallback($0, to)
                    }
                })
            } else {
                ForEach(tracks) { track in
                    ModifiedTrackListRow(track: track, album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, expand: track == tracks.last ? expand : nil)
                }
            }
        }
    }
    
    func sort(tracks: [Track]) -> [Track] {
        if album != nil {
            return tracks.sorted { $0.index < $1.index }
        } else {
            return tracks
        }
    }
    
    // ...
    struct ModifiedTrackListRow: View {
        let track: Track
        let album: Album?
        
        let startPlayback: (Track) -> ()
        let deleteCallback: DeleteCallback
        
        let expand: Expand?
        
        var body: some View {
            TrackListRow(track: track, album: album, deleteCallback: deleteCallback) {
                startPlayback(track)
            }
            .id(track.id)
            .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
            .modifier(DeleteSwipeActionModifier(track: track, callback: deleteCallback))
            .onAppear { expand?() }
        }
    }
}

extension TrackList {
    typealias Expand = (() -> Void)
    typealias LoadCallback = (() async -> Void)?
    
    typealias DeleteCallback = ((_ track: Track) -> Void)?
    typealias MoveCallback = ((_ track: Track, _ to: Int) -> Void)?
    
    struct DeleteSwipeActionModifier: ViewModifier {
        let track: Track
        let callback: DeleteCallback
        
        func body(content: Content) -> some View {
            if let callback = callback {
                content
                    .swipeActions(edge: .trailing) {
                        Button {
                            callback(track)
                        } label: {
                            Label("download.remove", systemImage: "trash.fill")
                                .tint(.red)
                        }
                    }
            } else {
                content
            }
        }
    }
}

// MARK: Helper

extension TrackList {
    func expand() {
        if !working && count > tracks.count, let loadMore = loadMore {
            working = true
            
            Task.detached {
                await loadMore()
                working = false
            }
        }
    }
    
    private func startPlayback(index: Int, shuffle: Bool) {
        AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: shuffle, playbackInfo: .init(container: container))
    }
    private func startPlayback(track: Track) {
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init(container: container))
        }
    }
}


#Preview {
    NavigationStack {
        List {
            TrackList(tracks: [Track.fixture], container: nil)
        }
        .listStyle(.plain)
    }
}
