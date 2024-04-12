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
    var dataProviderOverride: LibraryDataProvider? = nil
    
    @State private var album: Album?
    @State private var failed = false
    
    @State private var didPost = false
    
    var body: some View {
        if failed {
            ErrorView()
                .onAppear {
                    if dataProvider.albumNotFoundFallbackToLibrary && !didPost {
                        dismiss()
                        NotificationCenter.default.post(name: Navigation.navigateAlbumNotification, object: albumId)
                        
                        didPost = true
                    }
                }
        } else if let album = album {
            AlbumView(album: album, dataProviderOverride: dataProviderOverride)
        } else {
            LoadingView()
                .navigationBarBackButtonHidden()
                .task {
                    let provider = dataProviderOverride ?? dataProvider
                    if let album = try? await provider.getAlbum(albumId: albumId) {
                        self.album = album
                    } else {
                        self.failed = true
                    }
                }
        }
    }
}
