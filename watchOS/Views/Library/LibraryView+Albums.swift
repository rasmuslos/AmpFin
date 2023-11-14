//
//  LibraryView+Albums.swift
//  watchOS
//
//  Created by Rasmus Krämer on 14.11.23.
//

import SwiftUI
import MusicKit
import TipKit

extension LibraryView {
    struct AlbumsView: View {
        @Environment(\.libraryDataProvider) var dataProvider
        
        @State var albums: [Album]? = nil
        @State var failed = false
        
        var body: some View {
            Group {
                if let albums = albums {
                    TipView(ShuffleTip())
                    ItemList(items: albums)
                } else if failed {
                    ErrorView()
                } else {
                    LoadingView()
                        .onAppear {
                            Task.detached {
                                do {
                                    // TODO: this
                                    albums = try await dataProvider.getAlbums(limit: -1, sortOrder: .added, ascending: true)
                                } catch {
                                    failed = true
                                }
                            }
                        }
                }
            }
            .modifier(NowPlayingModifier())
        }
    }
}
