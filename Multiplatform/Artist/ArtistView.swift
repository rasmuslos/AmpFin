//
//  ArtistView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import Defaults
import AFBase
import AFPlayback

struct ArtistView: View {
    @Default(.sortOrder) private var sortOrder
    @Default(.sortAscending) private var sortAscending
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let artist: Artist
    
    @State private var count = 0
    @State private var albums = [Album]()
    
    private var sortState: [String] {[
        sortOrder.rawValue,
        sortAscending.description,
    ]}
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if artist.cover != nil {
                    Header(artist: artist)
                } else {
                    Color.clear
                }
                
                VStack {
                    if !albums.isEmpty {
                        HStack {
                            Text("artist.albums")
                                .font(.headline)
                            
                            Spacer()
                        }
                        .padding(.top, artist.cover == nil ? 0 : 17)
                        .padding(.horizontal, 20)
                        
                        AlbumGrid(albums: albums, count: count, loadMore: fetchAlbums)
                            .padding(.horizontal, 20)
                    } else {
                        Text("artist.empty")
                            .font(.headline.smallCaps())
                            .foregroundStyle(.secondary)
                            .padding(.top, 100)
                    }
                }
                .background(.background)
            }
        }
        .modifier(Toolbar(artist: artist))
        .modifier(NowPlayingBarSafeAreaModifier())
        .task {
            await fetchAlbums()
        }
        .onChange(of: sortState) {
            Task {
                albums = []
                await fetchAlbums()
            }
        }
        .userActivity("io.rfk.ampfin.artist") {
            $0.title = artist.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = artist.id
            $0.targetContentIdentifier = "artist:\(artist.id)"
            $0.userInfo = [
                "artistId": artist.id
            ]
            $0.webpageURL = JellyfinClient.shared.serverUrl.appending(path: "web").appending(path: "#").appending(path: "details").appending(queryItems: [
                .init(name: "id", value: "7b5e377b7908561ff476f35f8a0fa3ac"),
            ])
        }
    }
}

// MARK: Helper

extension ArtistView {
    func fetchAlbums() async {
        if let result = try? await dataProvider.getAlbums(artistId: artist.id, limit: 100, startIndex: albums.count, sortOrder: sortOrder, ascending: sortAscending) {
            count = result.1
            albums += result.0
        }
    }
}

#Preview {
    NavigationStack {
        ArtistView(artist: Artist.fixture)
    }
}

#Preview {
    NavigationStack {
        ArtistView(artist: {
            let artist = Artist.fixture
            artist.cover = nil
            
            return artist
        }())
    }
}
