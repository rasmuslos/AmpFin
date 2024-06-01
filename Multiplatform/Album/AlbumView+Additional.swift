//
//  AlbumView+Additional.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import AmpFinKit

extension AlbumView {
    struct AdditionalAlbums: View {
        @Environment(\.libraryDataProvider) private var dataProvider
        
        let album: Album
        
        @State private var similar = [Album]()
        @State private var alsoByArtist = [Album]()
        
        @State private var completedOperations = 0
        
        var body: some View {
            if completedOperations < 1 {
                ProgressView()
                    .frame(height: 0)
                    .listRowSeparator(.hidden)
                    .padding(.horizontal, 20)
                    .task { await loadSimilarAlbums() }
                    .task { await loadAlbumsByArtist() }
            }
            
            Group {
                if !alsoByArtist.isEmpty, let first = album.artists.first {
                    AlbumRow(title: String(localized: "album.similar \(first.name)"), albums: alsoByArtist)
                        .padding(.vertical, 12)
                }
                
                if !similar.isEmpty {
                    AlbumRow(title: String(localized: "album.similar"), albums: similar)
                        .padding(.vertical, 12)
                }
            }
            .refreshable { await loadSimilarAlbums() }
            .refreshable { await loadAlbumsByArtist() }
        }
        
        func loadSimilarAlbums() async {
            guard dataProvider as? OfflineLibraryDataProvider == nil else {
                completedOperations += 1
                return
            }
            
            guard let similar = try? await JellyfinClient.shared.albums(similarToAlbumId: album.id).filter({ $0.id != album.id }) else {
                completedOperations += 1
                return
            }
            
            guard !Task.isCancelled else {
                completedOperations += 1
                return
            }
            
            completedOperations += 1
            self.similar = similar
        }
        func loadAlbumsByArtist() async {
            guard dataProvider as? OfflineLibraryDataProvider != nil, let artist = album.artists.first else {
                completedOperations += 1
                return
            }
            
            guard let alsoByArtist = try? await dataProvider.albums(artistId: artist.id, limit: 20, startIndex: 0, sortOrder: .released, ascending: false).0.filter({ $0.id != album.id }) else {
                completedOperations += 1
                return
            }
            
            guard !Task.isCancelled else {
                completedOperations += 1
                return
            }
            
            completedOperations += 1
            self.alsoByArtist = alsoByArtist
        }
    }
}
