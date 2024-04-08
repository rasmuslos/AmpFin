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
                        .padding(.horizontal)
                        
                        AlbumGrid(albums: albums, loadMore: fetchAlbums)
                            .padding()
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
        .modifier(NowPlayingBarSafeAreaModifier())
        .task {
            await fetchAlbums()
        }
        .refreshable {
            albums = []
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
            $0.userInfo = [
                "artistId": artist.id
            ]
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
