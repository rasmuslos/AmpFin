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
    var count: Int = 0
    
    var container: Item? = nil
    var preview: Bool = false
    
    var deleteCallback: TrackCollection.DeleteCallback = nil
    var moveCallback: TrackCollection.MoveCallback = nil
    var loadMore: TrackCollection.LoadCallback = nil
    
    private var album: Album? {
        container as? Album
    }
    private var sorted: [Track] {
        if album != nil {
            return tracks.sorted { $0.index < $1.index }
        } else {
            return tracks
        }
    }
    
    var body: some View {
            ForEach(sorted) { track in
                TrackListRow(track: track, container: container, preview: preview, deleteCallback: deleteCallback) {
                    if let index = tracks.firstIndex(where: { $0.id == track.id }) {
                        AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init(container: container))
                    }
                }
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .padding(.vertical, album != nil ? 8 : 4)
                .onAppear {
                    if track == tracks.last {
                        loadMore?()
                    }
                }
            }
            .onDelete { tracks in
                tracks.map { sorted[$0] }.forEach {
                    deleteCallback?($0)
                }
            }
            .onMove { from, to in
                from.map { tracks[$0] }.forEach {
                    moveCallback?($0, to)
                }
            }
            .deleteDisabled(deleteCallback == nil)
            .moveDisabled(moveCallback == nil)
            
            ForEach(0..<(min(10000, max(0, count - tracks.count))), id: \.hashValue) { _ in
                TrackListRow.placeholder
                    .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .onAppear {
                        loadMore?()
                    }
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
    .environment(NowPlaying.ViewModel())
}
