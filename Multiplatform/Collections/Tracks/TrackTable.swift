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
    @SceneStorage("TracksTableCustomisation") private var columnCustomization: TableColumnCustomization<Track>
    
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
        Table(of: Track.self, selection: $selection, columnCustomization: $columnCustomization) {
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
            .customizationID("name")
            
            if album == nil {
                TableColumn("table.album") {
                    if let albumName = $0.album.name {
                        Text(albumName)
                    } else {
                        Text("album.unknown")
                    }
                }
                .customizationID("album")
            }
            TableColumn("table.artist") {
                if let artistName = $0.artistName {
                    Text(artistName)
                } else {
                    Text("artist.unknown")
                }
            }
            .customizationID("artist")
            
            TableColumn("table.duration") {
                Text($0.runtime.duration)
            }
            .customizationID("duration")
            
            TableColumn("table.index") { track in
                Text("table.index \(track.index.disk) \(track.index.index)")
            }
            .defaultVisibility(.hidden)
            .customizationID("index")
            
            TableColumn("table.lufs") { track in
                if let lufs = track.lufs {
                    Text("table.lufs \(lufs)")
                }
            }
            .defaultVisibility(.hidden)
            .customizationID("lufs")
            
            TableColumn("table.plays") {
                Text("table.plays \($0.playCount)")
            }
            .defaultVisibility(.hidden)
            .customizationID("plays")
            
            TableColumn("table.released") { track in
                if let released = track.releaseDate {
                    Text(released, format: .dateTime)
                }
            }
            .defaultVisibility(.hidden)
            .customizationID("released")
            
            TableColumn(String()) { track in
                Menu {
                    TrackListRow.TrackMenu(track: track, album: album, deleteCallback: deleteCallback, addToPlaylistSheetPresented: .init(get: { addToPlaylistTrack == track }, set: {
                        if $0 {
                            addToPlaylistTrack = track
                        } else {
                            addToPlaylistTrack = nil
                        }
                    }))
                } label: {
                    Label("more", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                }
            }
            .width(min: 25, max: 40)
            .disabledCustomizationBehavior([.reorder, .visibility])
            .customizationID("menu")
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
