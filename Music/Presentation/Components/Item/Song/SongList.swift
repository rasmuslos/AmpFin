//
//  SongList.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct SongList: View {
    let songs: [SongItem]
    var includeButtons: Bool = true
    
    @State var search: String = ""
    
    var body: some View {
        if includeButtons {
            SongListButtons()
        }
        
        ForEach(filter()) { item in
            SongListItem(item: item)
        }
        
        if includeButtons {
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
    func filter() -> [SongItem] {
        if search != "" {
            return songs.filter { $0.name.contains(search) || $0.album.name.contains(search) }
        }
        
        return songs
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
