//
//  LibraryView+Tracks.swift
//  watchOS
//
//  Created by Rasmus Krämer on 14.11.23.
//

import SwiftUI
import MusicKit

extension LibraryView {
    struct TracksView: View {
        @Environment(\.libraryDataProvider) var dataProvider
        
        @State var tracks: [Track]? = nil
        @State var failed = false
        
        var body: some View {
            Group {
                if let tracks = tracks {
                    ItemList(items: tracks)
                } else if failed {
                    ErrorView()
                } else {
                    LoadingView()
                        .onAppear {
                            Task.detached {
                                do {
                                    // TODO: this
                                    tracks = try await dataProvider.getAllTracks(sortOrder: .added, ascending: true)
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
