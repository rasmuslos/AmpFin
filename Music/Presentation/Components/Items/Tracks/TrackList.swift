//
//  TrackList.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct TrackList: View {
    let tracks: [Track]
    var album: Album? = nil
    
    @State var search: String = ""
    
    var body: some View {
        if album == nil {
            TrackListButtons() {
                startPlayback(index: 0, shuffle: $0)
            }
            .searchable(text: $search, prompt: "search.tracks")
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        
        let disks = getDisks()
        
        if album != nil, disks.count > 1 {
            ForEach(disks.sorted(), id: \.hashValue) { disk in
                Section {
                    TrackSection(tracks: filter(tracks: tracks.filter { $0.index.disk == disk }), album: album, startPlayback: startPlayback)
                } header: {
                    Text("tracks.disk \(disk)")
                        .padding(.top, -20)
                }
            }
        } else {
            TrackSection(tracks: filter(tracks: tracks), album: album, startPlayback: startPlayback)
        }
    }
}

// MARK: Track section

extension TrackList {
    struct TrackSection: View {
        let tracks: [Track]
        let album: Album?
        
        let startPlayback: (Track) -> ()
        
        var body: some View {
            ForEach(tracks) { track in
                TrackListRow(track: track, album: album) {
                    startPlayback(track)
                }
                .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
                .padding(.horizontal)
            }
        }
    }
}

// MARK: Helper

extension TrackList {
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
    
    private func getDisks() -> [Int] {
        tracks.reduce([Int]()) {
            if !$0.contains($1.index.disk) {
                return $0 + [$1.index.disk]
            }
            
            return $0
        }
    }
    
    private func startPlayback(index: Int, shuffle: Bool) {
        AudioPlayer.shared.startPlayback(tracks: filter(tracks: tracks), startIndex: index, shuffle: shuffle)
    }
    private func startPlayback(track: Track) {
        let tracks = filter(tracks: tracks)
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            AudioPlayer.shared.startPlayback(tracks: tracks, startIndex: index, shuffle: false)
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
