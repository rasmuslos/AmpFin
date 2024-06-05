//
//  TrackList.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

internal struct TrackList: View {
    let tracks: [Track]
    let container: Item?
    
    var deleteCallback: TrackCollection.DeleteCallback = nil
    var moveCallback: TrackCollection.MoveCallback = nil
    
    var count = 0
    var loadMore: TrackCollection.LoadCallback = nil
    
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
                    TrackSection(tracks: sort(tracks: tracks.filter{ $0.index.disk == disk }), album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, moveCallback: moveCallback, loadMore: loadMore)
                } header: {
                    Text("tracks.disk \(disk)")
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .padding(.top, -30)
                }
            }
        } else {
            TrackSection(tracks: sort(tracks: tracks), album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, moveCallback: moveCallback, loadMore: loadMore)
        }
        
        ForEach(0..<(min(10000, max(0, count - tracks.count))), id: \.hashValue) { _ in
            TrackListRow.placeholder
                .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                .onAppear { loadMore?() }
        }
    }
}

private extension TrackList {
    func sort(tracks: [Track]) -> [Track] {
        if album != nil {
            return tracks.sorted { $0.index < $1.index }
        } else {
            return tracks
        }
    }
    
    func startPlayback(track: Track) {
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init(container: container))
        }
    }
}

private struct TrackSection: View {
    let tracks: [Track]
    let album: Album?
    
    let startPlayback: (Track) -> ()
    let deleteCallback: TrackCollection.DeleteCallback
    let moveCallback: TrackCollection.MoveCallback
    let loadMore: TrackCollection.LoadCallback
    
    var body: some View {
        if let moveCallback = moveCallback {
            ForEach(tracks) { track in
                ModifiedTrackListRow(track: track, album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, loadMore: track == tracks.last ? loadMore : nil)
            }
            .onDelete(perform: { _ in })
            .onMove(perform: { from, to in
                from.map { tracks[$0] }.forEach {
                    moveCallback($0, to)
                }
            })
        } else {
            ForEach(tracks) { track in
                ModifiedTrackListRow(track: track, album: album, startPlayback: startPlayback, deleteCallback: deleteCallback, loadMore: track == tracks.last ? loadMore : nil)
            }
        }
    }
}

private struct ModifiedTrackListRow: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let track: Track
    let album: Album?
    
    let startPlayback: (Track) -> ()
    let deleteCallback: TrackCollection.DeleteCallback
    
    let loadMore: TrackCollection.LoadCallback
    
    var body: some View {
        TrackListRow(track: track, album: album, deleteCallback: deleteCallback) {
            startPlayback(track)
        }
        .id(track.id)
        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
        .modifier(DeleteSwipeActionModifier(track: track, callback: deleteCallback))
        .onAppear { loadMore?() }
    }
}

private struct DeleteSwipeActionModifier: ViewModifier {
    let track: Track
    let callback: TrackCollection.DeleteCallback
    
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

#Preview {
    NavigationStack {
        List {
            TrackList(tracks: [Track.fixture], container: nil)
                .padding(.horizontal, 20)
        }
        .listStyle(.plain)
    }
}
