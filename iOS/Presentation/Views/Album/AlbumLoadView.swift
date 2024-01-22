//
//  AlbumLoadView.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI
import AFBase

struct AlbumLoadView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    @Environment(\.dismiss) var dismiss
    
    let albumId: String
    
    @State var album: Album?
    @State var failed = false
    
    @State var didPost = false
    
    var body: some View {
        if failed {
            ErrorView()
                .onAppear {
                    if dataProvider.albumNotFoundFallbackToLibrary && !didPost {
                        dismiss()
                        NotificationCenter.default.post(name: NavigationRoot.navigateAlbumNotification, object: albumId)
                        
                        didPost = true
                    }
                }
        } else if let album = album {
            AlbumView(album: album)
        } else {
            LoadingView()
                .navigationBarBackButtonHidden()
                .task {
                    if let album = try? await dataProvider.getAlbumById(albumId) {
                        self.album = album
                    } else {
                        self.failed = true
                    }
                }
        }
    }
}
