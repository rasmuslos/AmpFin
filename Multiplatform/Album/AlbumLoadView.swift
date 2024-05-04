//
//  AlbumLoadView.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI
import AFBase

struct AlbumLoadView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    @Environment(\.dismiss) private var dismiss
    
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
        } else if let album = album {
            AlbumView(album: album)
        } else {
            LoadingView()
                .navigationBarBackButtonHidden()
                .task {
                    if let album = try? await dataProvider.getAlbum(albumId: albumId) {
                        self.album = album
                    } else {
                        self.failed = true
                    }
                }
        }
    }
}
