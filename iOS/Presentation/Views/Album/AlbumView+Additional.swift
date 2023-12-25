//
//  AlbumView+Additional.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import AFBaseKit

extension AlbumView {
    struct AdditionalAlbums: View {
        @Environment(\.libraryDataProvider) var dataProvider
        
        let album: Album
        
        @State var alsoFromArtist: [Album]?
        @State var similar: [Album]?
        
        var body: some View {
            // i hate this so much
            Divider()
                .frame(height: 0)
                .listRowSeparator(.hidden)
                .padding(.horizontal)
                .task(fetchAlbums)
            
            if let alsoFromArtist = alsoFromArtist, alsoFromArtist.count > 1, let first = album.artists.first {
                AlbumRow(title: String(localized: "album.similar \(first.name)"), albums: alsoFromArtist)
            }
            
            if let similar = similar, !similar.isEmpty {
                AlbumRow(title: String(localized: "album.similar"), albums: similar)
            }
        }
    }
}

// MARK: Helper

extension AlbumView.AdditionalAlbums {
    @Sendable
    func fetchAlbums() {
        if dataProvider as? OfflineLibraryDataProvider != nil {
            return
        }
        
        Task.detached {
            if let artist = album.artists.first {
                alsoFromArtist = try? await JellyfinClient.shared.getAlbums(artistId: artist.id, sortOrder: .released, ascending: false).filter { $0.id != album.id }
            }
        }
        Task.detached {
            similar = try? await JellyfinClient.shared.getAlbums(similarToAlbumId: album.id)
        }
    }
}
