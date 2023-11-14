//
//  ItemList.swift
//  watchOS
//
//  Created by Rasmus Krämer on 14.11.23.
//

import SwiftUI
import MusicKit

struct ItemList: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let items: [Item]
    
    var body: some View {
        List {
            Button {
                if let tracks = items as? [Track] {
                    AudioPlayer.shared.startPlayback(tracks: tracks, startIndex: 0, shuffle: true)
                } else if let albums = items as? [Album] {
                    Task {
                        if let album = albums.randomElement(), let tracks = try? await dataProvider.getAlbumTracks(id: album.id) {
                            AudioPlayer.shared.startPlayback(tracks: tracks, startIndex: 0, shuffle: true)
                        }
                    }
                } else if items as? [Artist] != nil {
                    Task {
                        if let tracks = try? await dataProvider.getAllTracks(sortOrder: .added, ascending: true) {
                            AudioPlayer.shared.startPlayback(tracks: tracks, startIndex: 0, shuffle: true)
                        }
                    }
                }
            } label: {
                Label("shuffle", systemImage: "shuffle")
            }
            
            ForEach(items) { item in
                Button {
                    if let tracks = items as? [Track] {
                        AudioPlayer.shared.startPlayback(tracks: tracks, startIndex: items.firstIndex { $0.id == item.id }!, shuffle: false)
                    }
                } label: {
                    ItemRow(item: item)
                }
                // TODO: swipe gestures
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture()
                    .onEnded {
                        if let album = item as? Album {
                            startPlayback(album: album, shuffle: false)
                        }
                    })
                .simultaneousGesture(LongPressGesture()
                    .onEnded { _ in
                        if let album = item as? Album {
                            startPlayback(album: album, shuffle: true)
                        }
                    })
            }
        }
    }
}

// MARK: Playback

extension ItemList {
    private func startPlayback(album: Album, shuffle: Bool) {
        Task {
            if let tracks = try? await JellyfinClient.shared.getAlbumTracks(id: album.id) {
                AudioPlayer.shared.startPlayback(tracks: tracks, startIndex: 0, shuffle: shuffle)
            }
        }
    }
}

#Preview {
    ItemList(items: [
        Track.fixture,
        Track.fixture,
        Track.fixture,
        Track.fixture,
        Track.fixture,
        Track.fixture,
        Track.fixture,
    ])
}

#Preview {
    ItemList(items: [
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
        Album.fixture,
    ])
}
