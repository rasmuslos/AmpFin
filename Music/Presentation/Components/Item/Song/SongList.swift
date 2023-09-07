//
//  SongList.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct SongList: View {
    let songs: [SongItem]
    var album: AlbumItem? = nil
    
    @State var search: String = ""
    
    var body: some View {
        if album == nil {
            SongListButtons() {
                startPlayback(index: 0, shuffle: $0)
            }
        }
        
        ForEach(Array(filter().enumerated()), id: \.offset) { index, item in
            Button {
                startPlayback(index: index, shuffle: false)
            } label: {
                SongListItem(item: item, album: album)
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

extension SongList {
    private func filter() -> [SongItem] {
        var filtered = songs
        
        if search != "" {
            filtered = filtered.filter { $0.name.contains(search) || $0.album.name.contains(search) }
        }
        
        return filtered.sorted { $0.index < $1.index }
    }
    
    private func startPlayback(index: Int, shuffle: Bool) {
        AudioPlayer.shared.startPlayback(items: filter(), startIndex: index, shuffle: shuffle)
    }
}


#Preview {
    NavigationStack {
        List {
            SongList(songs: [SongItem.fixture])
        }
        .listStyle(.plain)
    }
}
