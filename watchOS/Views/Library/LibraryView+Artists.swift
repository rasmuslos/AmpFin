//
//  LibraryView+Artists.swift
//  watchOS
//
//  Created by Rasmus Krämer on 14.11.23.
//

import Foundation


import SwiftUI
import MusicKit

extension LibraryView {
    struct ArtistsView: View {
        @Environment(\.libraryDataProvider) var dataProvider
        
        let albumOnly: Bool
        
        @State var artists: [Artist]? = nil
        @State var failed = false
        
        var body: some View {
            Group {
                if let artists = artists {
                    ItemList(items: artists)
                } else if failed {
                    ErrorView()
                } else {
                    LoadingView()
                        .onAppear {
                            Task.detached {
                                do {
                                    artists = try await dataProvider.getArtists(albumOnly: albumOnly)
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
