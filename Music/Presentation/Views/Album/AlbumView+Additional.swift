//
//  AlbumView+Additional.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI

extension AlbumView {
    struct AdditionalAlbums: View {
        let album: Album
        
        @State var alsoFromArtist: [Album]?
        
        var body: some View {
            if let alsoFromArtist = alsoFromArtist, !alsoFromArtist.isEmpty {
                AlbumRow(title: "Also from \(album.artists.first?.name ?? "this artist")", albums: alsoFromArtist)
            } else {
                Color.clear
                    .task(fetchAlbums)
                    .refreshable(action: fetchAlbums)
                    .listRowSeparator(.hidden)
                    .frame(height: 0)
            }
        }
    }
}

// MARK: Helper

extension AlbumView.AdditionalAlbums {
    @Sendable
    func fetchAlbums() {
        Task.detached {
            if let artist = album.artists.first {
                alsoFromArtist = try? await JellyfinClient.shared.getArtistAlbums(artistId: artist.id, sortOrder: .released, ascending: false)
            }
        }
    }
}
