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
        }
        
        ForEach(Array(filter().enumerated()), id: \.offset) { index, track in
            Button {
                startPlayback(index: index, shuffle: false)
            } label: {
                TrackListRow(track: track, album: album)
            }
            .buttonStyle(.plain)
            .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
            .padding(.horizontal)
        }
        
        if album == nil {
            // .searchable adds padding... for some reason
            Color.clear
                .searchable(text: $search, prompt: "Search")
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .frame(height: 0)
        }
    }
}

// MARK: Helper

extension TrackList {
    private func filter() -> [Track] {
        var filtered = tracks
        
        if search != "" {
            filtered = filtered.filter { $0.name.contains(search) || $0.album.name.contains(search) }
        }
        
        return filtered.sorted { $0.index < $1.index }
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
