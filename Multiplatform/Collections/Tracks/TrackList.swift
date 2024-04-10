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
    var album: Album? = nil
    
    var hideButtons = false
    var deleteCallback: DeleteCallback = nil
    var moveCallback: MoveCallback = nil
    
    var count = 0
    var loadMore: LoadCallback = nil
    
    @State private var working = false
    @State private var search: String = ""
    
    private var disks: [Int] {
        tracks.reduce([Int]()) {
            if !$0.contains($1.index.disk) {
                return $0 + [$1.index.disk]
            }
            
            return $0
        }
    }
    
    var body: some View {
        if !hideButtons {
            TrackListButtons() {
                startPlayback(index: 0, shuffle: $0)
            }
            .searchable(text: $search, placement: .navigationBarDrawer, prompt: "search.tracks")
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 10, trailing: 0))
        }
        
        if album != nil, disks.count > 1 {
            ForEach(disks.sorted(), id: \.hashValue) { disk in
                Section {
                    TrackSection(tracks: filter(tracks: tracks.filter { $0.index.disk == disk }), album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, moveCallback: moveCallback, expand: expand)
                } header: {
                    Text("tracks.disk \(disk)")
                        .padding(.top, -20)
                }
            }
        } else {
            TrackSection(tracks: filter(tracks: tracks), album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, moveCallback: moveCallback, expand: expand)
        }
        
        ForEach(0..<(max(0, count - tracks.count)), id: \.hashValue) { _ in
            TrackListRow.placeholder
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
            .padding(.horizontal)
            .modifier(DeleteSwipeActionModifier(track: track, callback: deleteCallback))
            .onAppear { expand?() }
        }
    }
}

extension TrackList {
    typealias Expand = (() -> Void)
    typealias LoadCallback = ((_ search: String?) async -> Void)?
    
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
                            Image(systemName: "trash.fill")
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
            
            let search: String?
            
            if self.search.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                search = nil
            } else {
                search = self.search
            }
            
            Task.detached {
                await loadMore(search)
                working = false
            }
        }
    }
    
    private func filter(tracks: [Track]) -> [Track] {
        var tracks = tracks
        
        if search != "" {
            tracks = tracks.filter { $0.name.lowercased().contains(search.lowercased()) || ($0.album.name?.lowercased() ?? "").contains(search.lowercased()) }
        }
        
        if album != nil {
            return tracks.sorted { $0.index < $1.index }
        } else {
            return tracks
        }
    }
    
    private func startPlayback(index: Int, shuffle: Bool) {
        AudioPlayer.current.startPlayback(tracks: filter(tracks: tracks), startIndex: index, shuffle: shuffle, playbackInfo: .init(type: .tracks, query: search, container: nil))
    }
    private func startPlayback(track: Track) {
        let tracks = filter(tracks: tracks)
        
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init(type: .tracks, query: search, container: nil))
        }
    }
}


#Preview {
    NavigationStack {
        List {
            TrackList(tracks: [Track.fixture])
        }
        .listStyle(.plain)
    }
}
