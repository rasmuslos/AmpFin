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
            .searchable(text: $search, prompt: "Search")
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        
        ForEach(Array(filter().enumerated()), id: \.offset) { index, track in
            TrackListRow(track: track, album: album) {
                startPlayback(index: index, shuffle: false)
            }
            .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
            .padding(.horizontal)
        }
    }
}

// MARK: Helper

extension TrackList {
    private func filter() -> [Track] {
        var filtered = tracks
        
        if search != "" {
            filtered = filtered.filter { $0.name.lowercased().contains(search.lowercased()) || $0.album.name.lowercased().contains(search.lowercased()) }
        }
        
        if album != nil {
            return filtered.sorted { $0.index < $1.index }
        } else {
            return filtered
        }
    }
    
    private func startPlayback(index: Int, shuffle: Bool) {
        AudioPlayer.shared.startPlayback(tracks: filter(), startIndex: index, shuffle: shuffle)
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
