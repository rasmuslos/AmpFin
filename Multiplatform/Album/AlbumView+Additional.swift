//
//  AlbumView+Additional.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import AmpFinKit

internal extension AlbumView {
    struct AdditionalAlbums: View {
        @Environment(AlbumViewModel.self) private var albumViewModel
        
        var body: some View {
            if let first = albumViewModel.album.artists.first, !albumViewModel.albumsReleasedSameArtist.isEmpty {
                AlbumRow(title: String(localized: "album.similar \(first.name)"), albums: albumViewModel.albumsReleasedSameArtist, displayContext: .artist)
                    .padding(.vertical, 12)
            }
            
            if !albumViewModel.similarAlbums.isEmpty {
                AlbumRow(title: String(localized: "album.similar"), albums: albumViewModel.similarAlbums)
                    .padding(.vertical, 12)
            }
        }
    }
}
