//
//  LibraryView.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import MusicKit

struct ListenNowView: View {
    @State var dataProvider: LibraryDataProvider = OfflineLibraryDataProvider()
    
    @State var albums: [Album]? = nil
    @State var failed: Bool = false
    
    var body: some View {
        Group {
            if let albums = albums {
                AlbumList(albums: albums)
            } else if failed {
                ErrorView()
            } else {
                LoadingView()
                    .onAppear {
                        Task.detached {
                            if let albums = try? await dataProvider.getRecommendedAlbums(), !albums.isEmpty {
                                self.albums = albums
                            } else {
                                dataProvider = OnlineLibraryDataProvider()
                                
                                do {
                                    albums = try await dataProvider.getRecommendedAlbums()
                                } catch {
                                    failed = true
                                }
                            }
                        }
                    }
            }
        }
        .modifier(NowPlayingModifier())
    }
}

#Preview {
    ListenNowView()
}
