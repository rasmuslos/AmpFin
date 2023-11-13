//
//  LibraryView.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import MusicKit

struct LibraryView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    @State var albums: [Album]? = nil
    @State var failed: Bool = false
    
    var body: some View {
        Group {
            if let albums = albums {
                TabView {
                    ForEach(albums) { album in
                        AlbumTab(album: album)
                    }
                }
                .tabViewStyle(.verticalPage)
            } else if failed {
                ErrorView()
            } else {
                LoadingView()
                    .onAppear {
                        Task.detached {
                            do {
                                albums = try await dataProvider.getRecentAlbums()
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

#Preview {
    LibraryView()
}
