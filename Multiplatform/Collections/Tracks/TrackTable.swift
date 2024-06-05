//
//  TrackTable.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.06.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback

struct TrackTable: View {
    let tracks: [Track]
    let container: Item?
    
    var deleteCallback: TrackCollection.DeleteCallback = nil
    
    var count = 0
    var loadMore: TrackCollection.LoadCallback = nil
    
    @State private var selection: Track.ID? = nil
    @State private var addToPlaylistTrack: Track? = nil
    
    private var album: Album? {
        container as? Album
    }
    
    var body: some View {
        Table(of: Track.self, selection: $selection) {
            TableColumn("table.name") { track in
                HStack(spacing: 8) {
                    TrackCollection.TrackIndexCover(track: track, album: album)
                    Text(track.name)
                }
                .onAppear {
                    if tracks.last == track {
                        loadMore?()
                    }
                }
            }
            if album == nil {
                TableColumn("table.album") {
                    if let albumName = $0.album.name {
                        Text(albumName)
                    }
                }
            }
            TableColumn("table.artist") {
                if let artistName = $0.artistName {
                    Text(artistName)
                }
            }
            TableColumn("table.duration") {
                Text($0.runtime.duration)
            }
        } rows: {
            ForEach(tracks) { track in
                TableRow(track)
                    .contextMenu {
                        TrackListRow.TrackMenu(track: track, album: album, deleteCallback: deleteCallback, addToPlaylistSheetPresented: .init(get: { addToPlaylistTrack == track }, set: {
                            if $0 {
                                addToPlaylistTrack = track
                            } else {
                                addToPlaylistTrack = nil
                            }
                        }))
                    } preview: {
                        TrackListRow.TrackPreview(track: track)
                    }
            }
        }
        .sheet(item: $addToPlaylistTrack) {
            PlaylistAddSheet(track: $0)
        }
        .onChange(of: selection) {
            if let index = tracks.firstIndex(where: { $0.id == selection }) {
                AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init(container: container))
                selection = nil
            }
        }
    }
}

#Preview {
    TrackTable(tracks: [
        .fixture,
        .fixture,
        .fixture,
        .fixture,
        .fixture,
        .fixture,
        .fixture,
    ], container: nil)
}
