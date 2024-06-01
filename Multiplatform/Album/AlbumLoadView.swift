//
//  AlbumLoadView.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI
import AmpFinKit

struct AlbumLoadView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let albumId: String
    
    @State private var album: Album?
    @State private var failed = false
    
    @State private var didPost = false
    
    var body: some View {
        if failed {
            ErrorView()
                .onAppear {
                    if dataProvider.albumNotFoundFallbackToLibrary && !didPost {
                        dismiss()
                        Navigation.navigate(albumId: albumId)
                        
                        didPost = true
                    }
                }
                .refreshable { await loadAlbum() }
        } else if let album {
            AlbumView(album: album)
        } else {
            LoadingView()
                .task { await loadAlbum() }
                .refreshable { await loadAlbum() }
        }
    }
    
    private func loadAlbum() async {
        guard let album = try? await dataProvider.album(identifier: albumId) else {
            failed = true
            return
        }
        
        self.album = album
    }
}
