//
//  AlbumLoadView.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI
import MusicKit

struct AlbumLoadView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let albumId: String
    
    @State var album: Album?
    @State var failed = false
    
    var body: some View {
        if failed {
            ErrorView()
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
