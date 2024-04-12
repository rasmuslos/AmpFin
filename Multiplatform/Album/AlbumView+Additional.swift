//
//  AlbumView+Additional.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import AFBase

extension AlbumView {
    struct AdditionalAlbums: View {
        @Environment(\.libraryDataProvider) private var dataProvider
        
        let album: Album
        var dataProviderOverride: LibraryDataProvider? = nil
        
        @State var alsoFromArtist: [Album]?
        @State var similar: [Album]?
        
        @State var completedOperations = 0
        
        var body: some View {
            if completedOperations < 1 {
                ProgressView()
                    .frame(height: 0)
                    .listRowSeparator(.hidden)
                    .padding(.horizontal)
                    .task {
                        fetchAlbums()
                    }
            }
            
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
    func fetchAlbums() {
        let provider = dataProviderOverride ?? dataProvider
        if provider as? OfflineLibraryDataProvider != nil {
            completedOperations = 2
            return
        }
        
        Task.detached {
            if let artist = album.artists.first {
                alsoFromArtist = try? await JellyfinClient.shared.getAlbums(limit: 10, startIndex: 0, artistId: artist.id, sortOrder: .released, ascending: false).0.filter { $0.id != album.id }
            }
            
            completedOperations += 1
        }
        Task.detached {
            similar = try? await JellyfinClient.shared.getAlbums(similarToAlbumId: album.id)
            completedOperations += 1
        }
    }
}
